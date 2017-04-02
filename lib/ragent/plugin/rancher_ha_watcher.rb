# frozen_string_literal: true

require_relative 'rancher_ha_watcher/backend'
require_relative 'rancher_ha_watcher/rancher_fetcher'
require_relative 'rancher_ha_watcher/backend_writer'
require_relative 'rancher_ha_watcher/domainmap_writer'
require_relative 'rancher_ha_watcher/actor'

module Ragent
  module Plugin
    # plugin to watch container changes and adjust haproxy config files
    class RancherHaWatcher
      include Ragent::Plugin

      plugin_name 'rancher_ha_watcher'

      AGENT_NAME='rancher-watcher-actor'
      # tag, interval, label, domain, rancher_url
      def configure(*args)
        @options = args[0] || {}
        @fetcher_opts = @options.dup
        @fetcher_opts.delete(:backends_file)
        @fetcher_opts.delete(:domainmap_file)
        @fetcher_opts.delete(:interval)
      end

      def start
        agent(type: RancherHaWatcher::Actor,
              as: AGENT_NAME,
              args: [@options[:interval],
                     @fetcher_opts,
                     @options[:backends_file],
                     @options[:domainmap_file]])
      end

    end
  end
end

Ragent.ragent.plugins.register(Ragent::Plugin::RancherHaWatcher)
