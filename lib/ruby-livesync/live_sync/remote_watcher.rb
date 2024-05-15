module LiveSync
  class RemoteWatcher < Watcher

    attr_reader :notifier
    delegate_missing_to :notifier

    attr_reader :sync

    INOTIFY_SCRIPT = <<-HEREDOC
      tp=$(mktemp -u)
      mkfifo $tp
      inotifywait -mr -e %{events} --format "%%e %%w%%f" /mnt/4tb > $tp 2>/dev/null &
      ipid=$!
      trap "kill $ipid; rm -f $tp; exit" INT TERM EXIT
      while true; do
        timeout %{delay} cat < $tp | sort | uniq
      done
    HEREDOC

    def initialize sync=nil
      @sync = sync
    end

    def watch path, *modes, &block
      dir_rwatch path, *modes, &block
    end

    def dir_rwatch path, *modes, delay: 1
      modes = DEFAULT_MODES if modes.blank?
      stdin, stdout, stderr, @wait_thr = Open3.popen3 'bash -s'
      cmd = INOTIFY_SCRIPT % {events: modes.join(','), delay: delay}
      stdin.write cmd
      stdin.close
      Thread.new do
        stdout.sync = true
        stdout.each_line do |line|
          events,file = line.split ' ', 2
          events = events.split(',').map(&:downcase).map(&:to_sym)
          yield OpenStruct.new absolute_name: file.chomp, flags: events
        end
      end
      self
    end

    def run
      sleep 1.day while true
    end

  end
end
