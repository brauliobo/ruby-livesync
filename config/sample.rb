# name of the sync
# if it is an existing path then `source` is set this value
sync '4tb' do
  enabled = false

  # fork to user below, usually associated with private keys 
  user = :root

  delay = 5

  # event list from inotify
  # full list at https://manpages.ubuntu.com/manpages/latest/en/man1/inotifywait.1.html#events
  modes = %i[create modify]

  source = '/mnt/4tb/'
  target rsync: 'root@bhavapower:/mnt/extensor/4tb' do
    opts = '-ax --partial' # default
  end

  # possible values are: true, false, :initial, :watched
  delete = true

  excludes = [
    '.snapshots',
  ]

  log.info 'starting'
end

