module LiveSync
  class Sync

    include DSL

    attr_reader :name
    attr_reader :log
    attr_reader :watcher
    attr_reader :target

    def initialize name = nil, &block
      fill_name name
      source name if File.exist? name
      dsl_apply(&block)
    end

    def fill_name name
      return if @name
      self.ctx = @name = name
      @log = Log.new ctx
    end

    dsl :enabled, default: true

    dsl :user, default: :root
    dsl :source do |source|
      raise "#{ctx}: source isn't a directory" unless File.directory? source
      fill_name source
      @pathname = Pathname.new source
    end

    dsl :target, skip_set: true do |opts, &block|
      @target = Rsync.new self, opts[:rsync], &block if opts[:rsync]
    end

    dsl :delay, default: 5, type: Integer

    dsl :modes, default: %i[create modify], type: []

    dsl :delete, default: false, enum: [true,false] + %i[initial watched]

    dsl :excludes, default: []

    def start
      return log.warning('skipping disabled sync') && false unless enabled
      raise "#{ctx}: missing target" unless @target
      target.start
    end

    def guard
      fork do
        Process.setproctitle "livesync: sync #{ctx}"
        @watcher = RbWatcher.new self

        watch source
        target.initial
        sleep 1.day while true
      end
    end

    def watch dir
      @watcher.watch dir, *modes, excludes: excludes, delay: delay, &method(:sync)
    end

    def sync paths
      return if target.running?
      target.partial paths
    end

    protected

  end
end
