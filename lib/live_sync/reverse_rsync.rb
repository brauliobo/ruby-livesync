module LiveSync
  class ReverseRsync < Rsync

    dsl :watcher, default: :py_inotify do |name|
      klass   = :"#{name.to_s.camelize}Watcher"
      klass   = LiveSync.const_get klass
      watcher = klass.new sync
      raise "reverse_sync: provided #{name}, but it required a cmd watcher" unless watcher.is_a? CmdWatcher
      watcher
    end

    attr_reader :parent
    delegate :ssh, to: :parent

    def initialize parent, &block
      super parent.sync, parent.sync.dest, parent.sync.source, reverse: true

      @parent = parent
      opts << ' -u'
      parent.opts << ' -u'

    end
    
    def running?
      @wait_thr or parent.running?
    end

    def initial
      watcher.base_cmd = "#{rsh} #{userhost} #{watcher.base_cmd}"
      watch
      super
    end

    def start
      # reuse parent's ssh
    end

  end
end
