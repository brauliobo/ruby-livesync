module LiveSync
  class User

    def self.wrap user
      fork do
        Process.setproctitle "livesync: user #{user}"
        Process.uid = Process::UID.from_name user.to_s
        yield
      end
    end

  end
end
