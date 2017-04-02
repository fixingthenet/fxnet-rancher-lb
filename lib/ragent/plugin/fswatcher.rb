# frozen_string_literal: true


require 'rb-inotify'
require 'celluloid/io'
require "forwardable"


module Ragent
  module Plugin
    class Fswatcher
      class IWatcher
        include Celluloid
        include Celluloid::IO
        include Celluloid::Notifications

        extend Forwardable
        finalizer :stop
        include Ragent::Logging

        def_delegators :@notifier, :watch, :close, :to_io

        def initialize(watches)
          @notifier = INotify::Notifier.new
          watches.each do |path, *args|
            debug "watching: #{path}  #{args}"
            @notifier.watch(path, *args) do |event|
              debug "inotify: #{event.flags} #{event.absolute_name}"
              publish("fswatcher", event: event)
            end
          end
          @stop=false
        end

        def wait_readable
          until @stop
            Celluloid::IO.wait_readable(self) #this is using to_io!
            @notifier.process
          end
        end

        def process
          wait_readable
        end

        def stop
          @stop = true
          #debug "closing inotify"
          close
        end
      end

      include Ragent::Plugin
      #https://github.com/celluloid/celluloid/wiki/Gotchas#io-operations-you-expect-not-to-block-are-blocking
      include Celluloid::IO

      plugin_name 'fswatcher'

      def configure(*args)
        opts = args[0] || {}
        @watch=opts[:watch]
      end

      def start
        debug "starting"
       agent(
        type: IWatcher,
        as: 'iwatcher',
        args: [@watch]
        )
       agents('iwatcher').async.process
       debug "started"
      end

      def stop
        agents('iwatcher')&.terminate
      end

    end
  end
end

Ragent.ragent.plugins.register(Ragent::Plugin::Fswatcher)
