module LiveSync
  class PyWatchdogWatcher < CmdWatcher

    self.base_cmd = 'python'

    self.script = File.read "#{File.dirname __FILE__}/py/watchdog.py"

    def parsed_params path, *modes, recursive: true, delay: 1, excludes: [], **params
      {
        path:      path,
        recursive: if recursive then 'True' else 'False' end,
        events:    modes.join(','),
        delay:     delay,
        excludes:  excludes.map{ |e| "'#{e}'" }.join(','),
      }
    end

  end
end
