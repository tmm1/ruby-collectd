require 'collectd/interface'
require 'collectd/server'

Collectd::add_server 1

c = 0
loop do
  Collectd.ruby_collectd(:test).ping(:fun).gauge = 42 + Math.sin(Time.now.to_f / 600) * 23.5
  Collectd.ruby_collectd(:test).cpu(:time).counter = c
  c += 1
  sleep 0.01
end
