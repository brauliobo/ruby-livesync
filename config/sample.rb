# if the name below is an existing path then `source` is set this value
sync '4tb' do

  user = :root

  delay = 5

  source = '/mnt/4tb/'
  target = 'root@bhavapower:/mnt/extensor/4tb'

  rsync.opts = '-ax --partial' # default

  excludes = [
    '.snapshots',
  ]

  log.info 'starting'

end

