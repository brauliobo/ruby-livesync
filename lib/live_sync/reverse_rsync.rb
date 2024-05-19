module LiveSync
  class ReverseRsync < Rsync

    include DSL

    dsl :watcher, skip_set: true, default: :py_inotify do |name|
      klass = LiveSync.const_get :"#{name.to_s.camelize}Watcher"
      raise "Only command-line parser are supported for reverse sync" unless klass.is_a? CmdWatcher
      @watcher = klass.new
    end

    attr_reader :parent

    def initialize parent, &block
      super parent.sync, parent.sync.dest, parent.sync.source, reverse: true

      @parent = parent
      @opts  << ' -u'

      watch
    end

    def watch
      @watcher.watch dir, *modes, excludes: sync.excludes, delay: sync.delay, &method(:sync)
    end

    def sync paths
      return if parent.running?
      partial paths
    end

  end
end
