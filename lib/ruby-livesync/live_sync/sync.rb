module LiveSync
  class Sync

    include DSL

    attr_reader :name
    attr_reader :scheduler
    attr_reader :log
    attr_reader :watcher
    attr_reader :target

    def initialize name = nil, &block
      fill_name name
      source name if File.exist? name
      dsl_apply(&block)
      @to_sync = Set.new
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
        @watcher   = Watcher.new self
        @scheduler = Rufus::Scheduler.new

        watch source
        target.initial
        schedule
        sleep 1.day while true
      end
    end

    def track event
      path = event.absolute_name
      watch path if File.directory?(path) and :create.in? event.flags
      @to_sync << Pathname.new(path).relative_path_from(@pathname).to_s
    end

    def watch dir
      @watcher.dir_rwatch dir, *modes, &method(:track)
    end

    def schedule
      @scheduler.in "#{delay}s", &method(:check)
    end

    def check
      return if target.running?
      @watcher.process # calls #track
      return if @to_sync.blank?
      target.partial @to_sync
      @to_sync.clear
    ensure
      schedule
    end

    protected

  end
end
