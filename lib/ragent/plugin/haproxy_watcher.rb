module Ragent
  module Plugin
    class HaproxyWatcher
      include Ragent::Plugin
      plugin_name 'haproxy_watcher'

      def configure(*args)
        opts = args[0] || {}
        @config_file_paths = opts[:configfile_paths]
        @ha_controller = HaproxyController.new(pidfile_path: opts[:pidfile_path],
                                               configfile_paths: @config_file_paths,
                                               simulate: opts[:simulate])
      end

      def start
        subscribe('fswatcher', :config_fs_changes)
        subscribe('rancher_ha_watcher/config_change', :config_ha_changes)
        @ha_controller.start
      end

      def config_fs_changes(_topic, args)
        if @config_file_paths.include?(args[:event].absolute_name)
          info "change detected: #{args[:event].absolute_name}"
          @ha_controller.restart_if_ok
        end
      end

      def config_ha_changes(_topic, _args)
        info 'change detected: ha watcher'
        @ha_controller.restart_if_ok
      end

      class HaproxyController
        include Ragent::Logging

        HAPROXY_START_CMD = 'haproxy -D -p %{pidfile_path} %{config_args}'.freeze
        HAPROXY_CONFIG_CHECK = 'haproxy -c  %{config_args}'.freeze

        attr_reader :pidfile_path, :configfile_paths
        def initialize(pidfile_path:, configfile_paths:, simulate: false)
          @pidfile_path = pidfile_path
          @configfile_paths = configfile_paths
          @check_cmd = HAPROXY_CONFIG_CHECK % { config_args: config_args }
          @start_cmd = HAPROXY_START_CMD % { pidfile_path: @pidfile_path, config_args: config_args }

          @simulate = simulate
        end

        def to_s
          "check_cmd: #{@check_cmd}\nrestart_cmd: #{@restart_cmd}"
        end

        def check_config
          info "running: #{@check_cmd}"
          if @simulate
            true #check is always ok
          else
            system(@check_cmd)
          end
        end

        def start
          run_ha(@start_cmd)
        end

        def restart
          pid = File.read(@pidfile_path)
          restart_cmd = "#{HAPROXY_START_CMD} -sf %{pid}" % { pidfile_path: @pidfile_path, config_args: config_args, pid: pid }
          run_ha(restart_cmd)
        end

        def restart_if_ok
          if check_config
            restart
          else
            error "ERROR: config of lb not ok!"
          end
        end
        private

        def config_args
          @configfile_paths.map { |p| "-f #{p}" }.join(' ')
        end

        def run_ha(cmd)
          info "running: #{cmd}"
          system(cmd) unless @simulate
        end
      end
    end
  end
end

Ragent.ragent.plugins.register(Ragent::Plugin::HaproxyWatcher)
