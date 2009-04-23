require 'socket'
require 'pkt'

module Collectd

  class Sender
    def initialize(host, port=25826)
      @sock = UDPSocket.new(Socket::AF_INET6)
      @sock.connect(host, port)
    end
    
    def send!
      pkts = [Packet::Host.new("ruby-collectd"),
              Packet::Time.new(Time.now.to_i),
              Packet::Interval.new(10),
              Packet::Plugin.new("test"),
              Packet::PluginInstance.new("10"),
              Packet::Type.new("ping"),
              Packet::TypeInstance.new("fun"),
              Packet::Values.new([Packet::Values::Gauge.new(42 + Math.sin(Time.now.to_f / 600) * 23.5)]),
              #Packet::Message.new("Hello, World!")
             ]
      buf = pkts.join
      @sock.send(buf, 0)
    end
  end

end



s = Collectd::Sender.new('ff18::efc0:4a42')
loop do
  s.send!
  puts "Sent"
  sleep 10
end
