module Collectd
  # EventMachine support stuff. Included in Collectd::Plugin.
  module EmPlugin
    ##
    # Attaches additional callback and errback to deferrable to track
    # a common set of success/error rate/latency
    def track_deferrable(name, deferrable)
      attach_time = Time.now
      deferrable.callback do |*a|
        push_deferrable_values("#{name}_success", attach_time)
      end
      deferrable.errback do |*a|
        push_deferrable_values("#{name}_error", attach_time)
      end
    end
    def push_deferrable_values(name, attach_time)
      latency(name).gauge = Time.now - attach_time
      counter(name).count! 1
    end
  end
end
