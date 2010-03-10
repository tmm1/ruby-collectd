require 'collectd/pkt'
require 'collectd/em_support'


module Collectd
  class << self

    def hostname
      @@hostname ||= `hostname -f`.strip
      @@hostname
    end
    def hostname=(h)
      @@hostname = h
    end

    @@servers = []

    def add_server(interval, addr='ff18::efc0:4a42', port=25826)
      if defined?(EM) && EM.reactor_running?
        @@servers << EmServer.new(interval, addr, port)
      else
        @@servers << Server.new(interval, addr, port)
      end
    end

    def <<(server)
      @@servers << server
    end

    def reset!
      @@servers.each do |server|
        server.close if server.respond_to?(:close)
      end
      @@servers = []
      @@pollables = []
    end

    def each_server(&block)
      @@servers.each(&block)
    end

    def add_pollable(&block)
      @@pollables ||= []
      @@pollables << block
    end
    def run_pollables_for(server)
      @@pollables ||= []
      @@pollables.each do |block|
        block.call(server)
      end
    end

    def method_missing(plugin, plugin_instance)
      Plugin.new(plugin, plugin_instance)
    end

  end

  ##
  # Interface helper
  class Plugin
    include ProcStats
    include EmPlugin
    def initialize(plugin, plugin_instance)
      @plugin, @plugin_instance = plugin, plugin_instance
    end
    def method_missing(type, type_instance)
      Type.new(@plugin, @plugin_instance, type, type_instance)
    end
  end

  ##
  # Interface helper
  class Type
    def initialize(plugin, plugin_instance, type, type_instance)
      @plugin, @plugin_instance = plugin, plugin_instance
      @type, @type_instance = type, type_instance
    end
    ##
    # GAUGE
    def gauge=(values)
      values = [values] unless values.kind_of? Array
      Collectd.each_server do |server|
        server.set_gauge(plugin_type, values)
      end
    end
    ##
    # COUNTER
    def counter=(values)
      values = [values] unless values.kind_of? Array
      Collectd.each_server do |server|
        server.set_counter(plugin_type, values)
      end
    end
    def count!(*values)
      Collectd.each_server do |server|
        server.inc_counter(plugin_type, values)
      end
    end
    def polled_gauge(&block)
      Collectd.add_pollable do |server|
        values = block.call
        if values
          values = [values] unless values.kind_of? Array
          server.set_gauge(plugin_type, values)
        end
      end
    end
    def polled_count(&block)
      Collectd.add_pollable do |server|
        values = block.call
        if values
          values = [values] unless values.kind_of? Array
          server.inc_counter(plugin_type, values)
        end
      end
    end
    def polled_counter(&block)
      Collectd.add_pollable do |server|
        values = block.call
        if values
          values = [values] unless values.kind_of? Array
          server.set_counter(plugin_type, values)
        end
      end
    end
    private
    ##
    # [plugin, plugin_instance, type, type_instance]
    def plugin_type
      [@plugin, @plugin_instance, @type, @type_instance]
    end
  end

  ##
  # Value-holder, baseclass for servers
  class Values
    attr_reader :interval
    def initialize(interval)
      @interval = interval
      @counters = {}
      @gauges = {}
      @lock = Mutex.new
    end
    def set_counter(plugin_type, values)
      @lock.synchronize do
        @counters[plugin_type] = values
      end
    end
    def inc_counter(plugin_type, values)
      @lock.synchronize do
        old_values = @counters[plugin_type] || []
        values.map! { |value|
          value + (old_values.shift || 0)
        }
        @counters[plugin_type] = values
      end
    end
    def set_gauge(plugin_type, values)
      @lock.synchronize do
        # Use count & sums for average
        if @gauges.has_key?(plugin_type)
          old_values = @gauges[plugin_type]
          count = old_values.shift || 0
          values.map! { |value| value + (old_values.shift || value) }
          @gauges[plugin_type] = [count + 1] + values
        else
          @gauges[plugin_type] = [1] + values
        end
      end
    end

    def make_pkt
      @lock.synchronize do
        pkt = nil
        @plugin_type_values = {}

        @counters.each do |plugin_types,values|
          packet_values = Packet::Values.new(values.map { |value| Packet::Values::Counter.new(value) })
          populate_plugin_type_values(plugin_types, packet_values)
        end

        @gauges.each do |plugin_types,values|
          count = values.shift || next
          values.map! { |value| value.to_f / count }
          packet_values = Packet::Values.new(values.map { |value| Packet::Values::Gauge.new(value) })
          populate_plugin_type_values(plugin_types, packet_values)
        end

        pkt = [Packet::Host.new(Collectd.hostname),
               Packet::Time.new(Time.now.to_i),
               Packet::Interval.new(10)]

        @plugin_type_values.each do |plugin,plugin_instances|
          pkt << Packet::Plugin.new(plugin)
          plugin_instances.each do |plugin_instance,types|
            pkt << Packet::PluginInstance.new(plugin_instance)
            types.each do |type,type_instances|
              pkt << Packet::Type.new(type)
              type_instances.each do |type_instance,values|
                pkt << Packet::TypeInstance.new(type_instance)
                pkt << values
              end
            end
          end
        end

        # Reset only gauges. Counters are persistent for incrementing.
        @gauges = {}

        # And return serialized packet of parts
        pkt.to_s
      end
    end

    private
    def populate_plugin_type_values(plugin_types, packet_values)
      plugin, plugin_instance, type, type_instance = plugin_types
      @plugin_type_values[plugin] ||= {}
      @plugin_type_values[plugin][plugin_instance] ||= {}
      @plugin_type_values[plugin][plugin_instance][type] ||= {}
      @plugin_type_values[plugin][plugin_instance][type][type_instance] = packet_values
    end

  end

end
