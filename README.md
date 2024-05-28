# ruby-livesync
### Fast and Lightweight Synchronization Daemon

`ruby-livesync` is a high-performance synchronization tool built as a response to the limitations observed in [lsyncd](https://github.com/lsyncd/lsyncd).
While lsyncd is an excellent tool, its performance with large filesystems—especially when using the MODIFY mode of inotify—was less than optimal, often consuming 5-10% CPU usage.
This led to the creation of `ruby-livesync`, a more efficient solution designed to handle large-scale synchronization tasks with ease.

## Key Features

- **Multi-User Support**: Efficiently manages multiple synchronization processes under a forked process for each specified user.
- **Persistent SSH Connections**: Reduces overhead by reusing a SSH connection for multiple rsync calls to the same destination.
- **Bidirectional Sync**: Reverse Sync supported via pyinotify on the remote host and rsync's --update. CAUTION: still in beta
- **Optimized Resource Usage**: Achieves near-zero CPU usage by processing inotify events at specified intervals and minimal memory usage by monitoring directories only.
- **Streamlined Logging**: Outputs only pertinent information directly through systemd, eliminating the need for managing custom log files.
- **Flexible Configuration**: Configuration files are written in Ruby, offering enhanced flexibility and ease of customization.

## Current Project Status

`ruby-livesync` is currently in its Beta phase, with active development focused on refining features and enhancing functionality.
The interface and features may undergo changes as the project evolves.

## Getting Involved

Long-term, ongoing support and development by the community will be crucial for `ruby-livesync`.
Contributions to the codebase are highly welcome, whether they be new features, bug fixes, or improvements.
The code is intentionally designed to be straightforward and flexible, ideal for developers looking to add new synchronization options or enhancements.

### Configuration
After installation, you'll need to configure ruby-livesync for use. Configuration file should be placed in `/etc/livesync/`.

Start by copying the sample configuration file at [config/sample.rb](config/sample.rb) to `/etc/livesync/config.rb`.

Below is a commented sample config file
```ruby
# name of the sync
# if it is an existing path then `source` is set this value
sync '4tb' do
  enabled = false

  # watchers available:
  # - :rb (default)
  # - :py_inotify
  # - :cmd (inotifywait)
  # - :py_watchdog
  #
  watcher = :rb

  # fork to user below, usually associated with private keys 
  user = :root

  # interval to collect all watched events and run rsync
  delay = 5

  # event list from inotify
  # full list at https://man.archlinux.org/man/inotifywait.1#EVENTS
  modes = %i[create modify delete]

  source = '/mnt/4tb/'
  target rsync: 'user@remote:/mnt/4tb' do
    opts = '-ax --partial' # default

    # enables bidirectional sync, using rsync's --update and a pyinotify based watcher
    reverse_sync
  end

  # possible values are: true, false, :initial, :watched
  delete = true

  excludes = [
    '.snapshots',
  ]

  log.info 'starting'
end
```

## Installation and Usage

ruby-livesync is available for installation either as a RubyGem or as an Arch Linux package from the AUR. Follow the steps below for your preferred installation method.

### Installing as a RubyGem
To install ruby-livesync via RubyGems, simply run the following command in your terminal:
```
gem install ruby-livesync
```
This will download and install the latest version of ruby-livesync along with its dependencies. Ensure that you have Ruby and RubyGems installed on your system before running this command.

### Installing from the Arch User Repository (AUR)
For Arch Linux users, ruby-livesync is available as an AUR package. You can install it using an AUR helper such as yay or paru. For example:
```
yay -S ruby-livesync
```

### System Service Setup
ruby-livesync can be run as a system service using systemd. A [standard unit file](livesync.service) is provided within the AUR package

### Contributing

If you're interested in contributing, please check out the issues on GitHub or submit your pull requests.
For major changes, please open an issue first to discuss what you would like to change.

## Support and Documentation

