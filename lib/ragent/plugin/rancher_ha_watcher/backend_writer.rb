require_relative 'update_writer'
module Ragent
  module Plugin
    class RancherHaWatcher
      class BackendWriter < UpdateWriter
        def create_new_content(backends)
          File.open(@tmpfile_name, 'w') do |fd|
            backends.keys.sort.each do |backend_name| # sort the backend names
              fd.puts "backend #{backend_name}"
              fd.puts '  mode http'
#              fd.puts '  http-send-name-header X-Backend-Name'
              backends[backend_name].sort_by(&:backend_id).each do |backend|
                fd.puts backend.haproxy_line
              end
              fd.puts '' # newline
            end
          end
        end
      end
    end
  end
end
