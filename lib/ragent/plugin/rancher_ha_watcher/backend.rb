module Ragent
  module Plugin
    class RancherHaWatcher
      class Backend
        attr_reader :ip, :port, :stack_name, :service_name, :uuid, :fqdns

        def initialize(ip:, port:, stack_name:, service_name:, uuid:, fqdns:)
          @ip = ip
          @port = port
          @stack_name = stack_name
          @service_name = service_name
          @uuid = uuid
          @fqdns = fqdns
        end

        def haproxy_line
          "  server #{backend_id} #{@ip}:#{@port}"
        end

        def backend_name
          "#{@stack_name}-#{service_name}"
        end

        def backend_id
          "#{@service_name}-#{@uuid}"
        end

        def to_s
          "Backend: #{@stack_name}: #{backend_id} #{@port} #{@fqdns.inspect}"
        end
      end

    end

  end
end
