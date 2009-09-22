require 'eventmachine'

module Collectd
  class EmServer < Values

    def initialize(interval, host, port)
      super(interval)
      @sock = UDPSocket.new(host.index(':') ? Socket::AF_INET6 : Socket::AF_INET)
      @sock.connect(host, port)

      EM.add_periodic_timer(interval) do
        Collectd.run_pollables_for self
        Thread.critical = true
        pkt = make_pkt
        Thread.critical = false
        begin
          @sock.send(pkt, 0)
        rescue SystemCallError
        end
      end
    end

  end
end
