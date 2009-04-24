require 'socket'
require 'thread'

module Collectd
  class Server < Values

    def initialize(interval, host, port)
      super(interval)
      @sock = UDPSocket.new(Socket::AF_INET6)
      @sock.connect(host, port)

      Thread.new do
        loop do
          sleep interval

          Thread.critical = true
          pkt = make_pkt
          Thread.critical = false
          @sock.send(pkt, 0)
        end
      end.abort_on_exception = true
    end

  end
end
