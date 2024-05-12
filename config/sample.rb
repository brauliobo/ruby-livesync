# if the name below is an existing path then `source` is set this value
sync '4tb' do

  user = :root

  source = '/mnt/4tb/'
  target = 'root@bhavapower:/mnt/extensor/4tb'

  log.info 'starting'

end

