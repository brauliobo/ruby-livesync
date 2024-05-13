module LiveSync
  class Sync

    include DSL

    attr_reader :name
    attr_reader :scheduler
    attr_reader :log
    attr_reader :watcher
    attr_reader :ssh
    attr_reader :rsync

    def initialize name = nil
      fill_name name
      source name if File.exist? name
      @to_sync = Set.new
      @rsync   = Rsync.new self
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

    dsl :target do |target|
      @userhost, @target_path = target.split(':')
      raise "#{ctx}: missing target path" unless @target_path
      source File.join(@source, '') if File.basename(@source) == File.basename(@target_path)
    end

    dsl :delay, default: 5, type: Integer

    dsl :delete, default: false, enum: [true,false] + %i[initial watched]

    dsl :excludes, default: []

    def start
      return log.warning('skipping disabled sync') && false unless enabled
      raise "#{ctx}: missing target" unless @target
      @ssh = Ssh.connect @userhost
      sleep 1 and log.warning 'waiting for ssh' while !@ssh.available?
      true
    end

    def guard
      fork do
        Process.setproctitle "livesync: sync #{ctx}"
        @watcher   = Watcher.new self
        @scheduler = Rufus::Scheduler.new

        watch source
        @rsync.initial
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
      @watcher.dir_rwatch dir, &method(:track)
    end

    def schedule
      @scheduler.in "#{delay}s", &method(:check)
    end

    def check
      return if @rsync.running?
      @watcher.process # calls #track
      return if @to_sync.blank?
      @rsync.partial @to_sync
      @to_sync.clear
    ensure
      schedule
    end

    protected

  end
end
