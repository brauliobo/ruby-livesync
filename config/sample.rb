# name of the sync
# if it is an existing path then `source` is set this value
sync '4tb' do
  enabled = false

  # fork to user below, usually associated with private keys 
  user = :root

  delay = 5

  source = '/mnt/4tb/'
  target = 'root@bhavapower:/mnt/extensor/4tb'

  rsync.opts = '-ax --partial' # default

  # possible values are: true, false, :initial, :watched
  delete = true

  excludes = [
    '.snapshots',
  ]

  log.info 'starting'
end

