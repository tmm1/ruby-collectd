require 'collectd'

Collectd::add_server 1
Stats = Collectd::ruby_collectd(:test)
Stats.with_full_proc_stats

c = 0
loop do
  Stats.ping(:fun).gauge = 42 + Math.sin(Time.now.to_f / 600) * 23.5
  Stats.cpu(:time).counter = c
  c += 1
  Thread.pass
  sleep 0.01
  print '.'
  STDOUT.flush
end
