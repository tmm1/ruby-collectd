require 'socket'
require 'collectd/pkt'

module Collectd
  class Simple
    def initialize name, instance, opts = {}
      @name, @instance = name, instance

      @sock = UDPSocket.new
      @sock.connect opts[:host] || '239.192.74.66',
                    opts[:port] || 25826

      @hostname = opts[:hostname] || `/bin/hostname -s`.strip
      @interval = opts[:interval] || 10

      @counters, @gauges, @counts = {}, {}, {}
    end

    def counter_set name, val
      flush_outbound
      @counters[name] = val
    end

    def counter_inc name, val = 1
      flush_outbound
      @counters[name] = @counters.has_key?(name) ? @counters[name] + val : val
    end

    def gauge_set name, val
      flush_outbound
      @gauges[name] = @gauges.has_key?(name) ? @gauges[name] + val : val
      @counts[name] = @counts.has_key?(name) ? @counts[name] + 1 : 1.0
    end

    private

    def flush_outbound
      @time ||= Time.now

      if @time < Time.now - @interval
        @packet = [
          Packet::Host.new(@hostname),
          Packet::Time.new(@time.to_i),
          Packet::Interval.new(@interval),
          Packet::Plugin.new(@name),
          Packet::PluginInstance.new(@instance)
        ]

        @counters.each do |key, val|
          @packet << Packet::Type.new(:counter)
          @packet << Packet::TypeInstance.new(key)
          @packet << Packet::Values.new([ Packet::Values::Counter.new(val) ])
        end

        @gauges.each do |key, val|
          @packet << Packet::Type.new(:gauge)
          @packet << Packet::TypeInstance.new(key)
          @packet << Packet::Values.new([ Packet::Values::Gauge.new(val/@counts[key]) ])
        end
        @gauges = {}
        @counts = {}

        @sock.send @packet.join(''), 0

        @time = Time.now
      end
    end
  end
end

if __FILE__ == $0
  s = Collectd::Simple.new('ruby', 'test', :interval => 1)

  s.counter_set(:seconds, 5)
  while sleep(0.1)
    s.counter_inc(:seconds, 1)
    s.gauge_set(:sinwave, Math.sin(Time.now.to_f/60) * 100)
  end
end
