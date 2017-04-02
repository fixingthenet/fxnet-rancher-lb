require 'digest'
require 'fileutils'

module Ragent
  module Plugin
    class RancherHaWatcher
      class UpdateWriter
        include Ragent::Logging
        include Celluloid::Notifications

        def initialize(filename, *args)
          @filename = filename
          @tmpfile_name = "#{filename}.tmp"
          create_new_content(*args)
        end

        def changed?
          @new_hash ||= file_hash(@tmpfile_name)
          @old_hash ||= file_hash(@filename)
          #puts "filename: #{@filename} #{@new_hash} #{@old_hash}"
          @new_hash != @old_hash
        end

        def change
          if changed?
            diff=`diff #{@tmpfile_name} #{@filename}`
            FileUtils.mv(@tmpfile_name, @filename)
            info "#{@filename} changed: \n#{diff}"
            true
          else
            # no change!
            false
          end
        end

        private

        def file_hash(fname)
          Digest::SHA256.hexdigest(File.read(fname))
        rescue Errno::ENOENT
          '000000noent0000'
        end
        end
    end
  end
end
