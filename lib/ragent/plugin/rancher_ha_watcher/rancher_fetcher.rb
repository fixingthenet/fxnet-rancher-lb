require 'net/http'
require 'uri'
require 'json'
require 'set'

# fetches all! containers from ranchers metadata service
module Ragent
  module Plugin
    class RancherHaWatcher
      class RancherHaproxyFetcher
        include Ragent::Logging

        attr_reader :backends, :domains
        def initialize(rancher_url:, domain:, tag:, label:)
          @domain = domain
          @tag = tag
          @label = label
          @backends = {} # stack_name -> service -> Backend
          @domains = {} # fqdn -> stack_name-service_name
          @containers = rancher_containers(rancher_url)
        end

        def run
          @containers.select do |container|
            !container['labels'][@label].nil? &&
              container['state'] == 'running'
          end.map do |balanced|
            begin
              lb_config = JSON.parse(balanced['labels'][@label])
              belongs_to_this_lb = lb_config['tags'].include?(@tag)
              port = lb_config['port']
              fqdns = lb_config['fqdns'] || ["#{balanced['labels']['io.rancher.stack.name']}.#{@domain}"]
            rescue JSON::ParserError # just the port given (old school, remove after migration)
              warn "WARN: can't parse config for #{balanced['name']}"
              port = balanced['labels'][@label].to_i
              fqdns = ["#{balanced['labels']['io.rancher.stack.name']}.#{@domain}"]
              belongs_to_this_lb = true
            end
            ip = balanced['primary_ip'] || balanced["primaryIpAddress"]
            #debug "Container: #{balanced['labels']['io.rancher.stack_service.name']}, belongs: #{belongs_to_this_lb}, ip: #{ip}"
            #debug balanced
            next unless belongs_to_this_lb
            next unless ip# TODO: do validation in Backend
            Backend.new(ip: ip,
                        stack_name: balanced['labels']['io.rancher.stack.name'],
                        service_name: balanced['labels']['io.rancher.stack_service.name'].split('/')[1],
                        uuid: balanced['labels']['io.rancher.container.uuid'],
                        port: port,
                        fqdns: fqdns)
          end.compact.each do |backend|
            backend.fqdns.each do |fqdn|
              @domains[fqdn] ||= Set.new
              @domains[fqdn] << backend.backend_name
            end
            @backends[backend.backend_name] ||= []
            @backends[backend.backend_name] << backend
          end
        end

        def rancher_containers(rancher_url)
          url_path = rancher_url + '/containers?limit=2000'
          url = URI.parse(url_path)
          req = Net::HTTP::Get.new(url)
          req.add_field('Content-Type', 'application/json')
          req.add_field('Accept', 'application/json')
          req.basic_auth url.user, url.password if url.user && url.password
          res = Net::HTTP.new(url.host, url.port).start do |http|
            http.request(req)
          end
          if res.code == '200'
            all = JSON.parse(res.body)
            if all.kind_of?(Hash)
              all["data"] # going over API
            else
              all #going over metadata
            end
          else
            error "ERROR: request to url #{url} failed with #{res.code}"
            []
          end
        end

      end
    end
  end
end
