require 'collectd/pkt'


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
      @@servers << Server.new(interval, addr, port)
    end

    def each_server(&block)
      @@servers.each(&block)
    end

    def method_missing(plugin, plugin_instance)
      Plugin.new(plugin, plugin_instance)
    end

  end

  ##
  # Interface helper
  class Plugin
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
    def gauge=(values)
      values = [values] unless values.kind_of? Array
      Collectd.each_server do |server|
        server.set_gauge(plugin_type, values)
      end
    end
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
    end
    def set_counter(plugin_type, values)
      @counters[plugin_type] = values
    end
    def inc_counter(plugin_type, values)
      old_values = @counters[plugin_type] || []
      values.map! { |value|
        value + (old_values.shift || 0)
      }
      @counters[plugin_type] = values
    end
    def set_gauge(plugin_type, values)
      # Use count & sums for average
      if @gauges.has_key?(plugin_type)
        old_values = @gauges[plugin_type]
        count = old_values.shift
        values.map! { |value| value + (old_values.shift || value) }
        @gauges[plugin_type] = [count + 1] + values
      else
        @gauges[plugin_type] = [1] + values
      end
    end

    def make_pkt
      plugin_type_values = {}
      @counters.each do |plugin_types,values|
        plugin, plugin_instance, type, type_instance = plugin_types
        plugin_type_values[plugin] ||= {}
        plugin_type_values[plugin][plugin_instance] ||= {}
        plugin_type_values[plugin][plugin_instance][type] ||= {}
        plugin_type_values[plugin][plugin_instance][type][type_instance] =
        Packet::Values.new(values.map { |value| Packet::Values::Counter.new(value) })
      end
      @gauges.each do |plugin_types,values|
        plugin, plugin_instance, type, type_instance = plugin_types
        plugin_type_values[plugin] ||= {}
        plugin_type_values[plugin][plugin_instance] ||= {}
        plugin_type_values[plugin][plugin_instance][type] ||= {}
        count = values.shift
        values.map! { |value| value.to_f / count }
        plugin_type_values[plugin][plugin_instance][type][type_instance] =
        Packet::Values.new(values.map { |value| Packet::Values::Gauge.new(value) })
      end
      pkt = [Packet::Host.new(Collectd.hostname),
             Packet::Time.new(Time.now.to_i),
             Packet::Interval.new(10)]
      plugin_type_values.each do |plugin,plugin_instances|
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

end
