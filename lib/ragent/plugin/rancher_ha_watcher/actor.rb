module Ragent
  module Plugin
    # plugin to watch container changes and adjust haproxy config files
    class RancherHaWatcher
      class Actor
        include Celluloid
        include Celluloid::Notifications

        def initialize(interval, fetcher_opts, backends_file, domainmap_file)
          every(interval) do
            run(fetcher_opts,backends_file,domainmap_file)
          end
        end

        def run(fetcher_opts,backends_file,domainmap_file)
          fetcher = RancherHaproxyFetcher.new(fetcher_opts)
          fetcher.run
          bwriter = BackendWriter.new(backends_file,
                                      fetcher.backends)
          changed=bwriter.change
          dwriter = DomainMapWriter.new(domainmap_file,
                                        fetcher.domains)
          changed ||= dwriter.change
          publish("rancher_ha_watcher/config_change", {}) if changed
        end

      end #Actor
    end
  end
end
