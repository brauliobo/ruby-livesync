module LiveSync
  class Daemon

    def self.start config
      new(config).start
    end

    attr_reader :config

    def initialize config
      @config = config
      @pids   = []
      @syncs  = Hash.new{ |h, k| h[k] = [] }
    end

    def start
      Process.setpgrp rescue nil # not allowed in systemd
      Process.setproctitle 'livesync'
      instance_eval File.read(config), config
      run
      Process.waitall
    end

    def sync name_or_path, &block
      s = Sync.new name_or_path, &block
      @syncs[s.user] << s
    end

    protected

    def run
      @syncs.each do |user, syncs|
        User.wrap user do
          syncs.each do |s|
            s.guard if s.start
          rescue => e
            msg  = e.message
            msg += "\n#{e.backtrace.join "\n"}" if Log.debug?
            Log.fatal msg
          end
          Process.waitall
        end
      end
    end

  end
end
