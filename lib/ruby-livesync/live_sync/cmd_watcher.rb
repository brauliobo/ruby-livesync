module LiveSync
  class CmdWatcher < Watcher

    class_attribute :base_cmd
    self.base_cmd = 'bash -s'

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

    def watch path, *modes, **params
      modes  = DEFAULT_MODES if modes.blank?
      script = self.script % parsed_params(path, *modes, **params)
      stdin, stdout, stderr, @wait_thr = Open3.popen3 base_cmd
      stdin.write script
      stdin.close

      Thread.new do
        stdout.sync = true
        lines = stdout.each_line.each do |line|
          file,events = parse line
          yield [OpenStruct.new(absolute_name: file, flags: events)]
        end
      end
      Thread.new do
        STDERR.puts stderr.read
      end
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
      [file.chomp, events]
    end

  end
end
