lib = File.expand_path '../lib', __FILE__
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'ruby-livesync/live_sync/version'

Gem::Specification.new do |spec|

  spec.name          = 'ruby-livesync'
  spec.version       = LiveSync::VERSION
  spec.authors       = ['Braulio Oliveira']
  spec.email         = ['brauliobo@gmail.com']

  spec.summary       = %q{Lightweight and fast live sync daemon}
  spec.homepage      = 'https://github.com/brauliobo/ruby-livesync'
  spec.license       = 'GPLv3'

  spec.files         = `git ls-files lib`.split + ['bin/livesync']
  spec.bindir        = 'bin'
  spec.executables   = 'livesync'
  spec.require_paths = ['lib']

  spec.add_dependency 'pry'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'rb-inotify'
  spec.add_dependency 'rufus-scheduler'

end
