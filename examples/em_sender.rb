require 'eventmachine'
require 'collectd'

EM.run do
  Collectd::use_eventmachine = true
  Collectd::add_server 1

  c = 0
  EM.add_periodic_timer(0.01) do
    Collectd.ruby_collectd(:test).ping(:fun).gauge = 42 + Math.sin(Time.now.to_f / 600) * 23.5
    Collectd.ruby_collectd(:test).cpu(:time).counter = c

    c += 1
    print '.'
    STDOUT.flush
  end
end
