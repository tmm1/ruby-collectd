module Collectd
  class << self

    @@servers = []

    def server(interval, addr='ff18::efc0:4a42', port=25826)
      @@servers << Server.new(interval, addr, port)
    end

    def method_missing(method, *a)
    end

  end
end
