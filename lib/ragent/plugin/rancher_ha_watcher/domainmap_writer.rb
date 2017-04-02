require_relative 'update_writer'

module Ragent
  module Plugin
    class RancherHaWatcher
      class DomainMapWriter < UpdateWriter
        def create_new_content(domains)
          File.open(@tmpfile_name, 'w') do |fd|
            domains.keys.sort.reverse.each do |domain_name| # sort the fqdn (reverse as we could also match paths)
              fd.puts "#{domain_name} #{domains[domain_name].sort.join(' ')}"
            end
          end
        end
      end
    end
  end
end
