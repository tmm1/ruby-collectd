require 'socket'
require 'thread'

module Collectd
  class Server < Values

    def initialize(interval, host, port)
      super(interval)
      @sock = UDPSocket.new(host.index(':') ? Socket::AF_INET6 : Socket::AF_INET)
      @sock.connect(host, port)

      Thread.new do
        loop do
          sleep interval

          Collectd.run_pollables_for self
          Thread.critical = true
          pkt = make_pkt
          Thread.critical = false
          @sock.send(pkt, 0)
        end
      end.abort_on_exception = true
    end

  end
end
