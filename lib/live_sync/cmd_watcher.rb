module LiveSync
  class CmdWatcher < Watcher

    class_attribute :base_cmd
    self.base_cmd = 'bash -s'

    class_attribute :rsh

    class_attribute :script
    self.script = <<-HEREDOC
      tp=$(mktemp -u)
      mkfifo $tp
      inotifywait %{opts} -m -e %{events} --format "%%e %%w%%f" %{path} %{excludes} > $tp 2>/dev/null &
      ipid=$!
      trap "kill $ipid; rm -f $tp; exit" INT TERM EXIT
      while true; do
        timeout %{delay} cat < $tp | sort | uniq
      done
    HEREDOC

    def watch path, *modes, **params, &block
      modes  = DEFAULT_MODES if modes.blank?
      script = self.script % parsed_params(path, *modes, **params)
      log.debug "#{self.class.name}: running #{base_cmd}"
      stdin, stdout, stderr, @wait_thr = Open3.popen3 base_cmd
      stdin.write script
      stdin.close

      Thread.new do
        loop do
          events = stdout.each_line.map{ |l| parse l } while stdout.wait_readable(0.5)
          log.debug events.inspect
          notify events, &block if events.present?
          break if @wait_thr.join(0.5)
        end
      end
      Thread.new do
        stderr.each_line.each{ |line| STDERR.puts line }
      end
    end

    def watching?
      @wait_thr
    end

    def parsed_params path, *modes, recursive: true, delay: 1, excludes: [], **params
      opts  = '-r' if recursive
      {
        path:      path,
        opts:      opts,
        events:    modes.join(','),
        delay:     delay,
        excludes:  excludes.map{ |e| "'@#{e}'" }.join(' '),
      }
    end

    def parse line
      events,file = line.split ' ', 2
      events = events.split(',').map(&:downcase).map(&:to_sym)
      OpenStruct.new absolute_name: file.chomp, flags: events
    end

  end
end
