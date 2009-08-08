module Collectd
  module Packet

    class Part
      def to_s(content)
        [type, content.length + 4].pack("nn") + content
      end

      ##
      # Makes subclasses more declarative
      def self.type(number=nil)
        number ? @type = number : @type
      end

      def type
        self.class.type
      end
    end

    class String < Part
      def initialize(s)
        @s = s
      end
      def to_s
        super "#{@s}\000"
      end
    end

    class Number < Part
      def initialize(n)
        @n = n
      end
      def to_s
        super [@n >> 32, @n & 0xffffffff].pack("NN")
      end
    end

    class Host < String
      type 0
    end

    class Time < Number
      type 1
    end

    class Plugin < String
      type 2
    end

    class PluginInstance < String
      type 3
    end

    class Type < String
      type 4
    end

    class TypeInstance < String
      type 5
    end

    class Values < Part
      type 6
      def initialize(v)
        @v = v
      end
      def to_s
        types, values = [], []
        @v.each { |v1|
          types << [v1.type].pack("C")
          values << v1.to_s
        }
        super [@v.length].pack("n") + types.join + values.join
      end

      class Counter < Part
        type 0
        def initialize(c)
          @c = c
        end
        def to_s
          [@c >> 32, @c & 0xffffffff].pack("NN")
        end
      end

      class Gauge < Part
        type 1
        def initialize(f)
          @f = f
        end
        def to_s
          [@f].pack("d")
        end
      end
    end

    class Interval < Number
      type 7
    end


    class Message < String
      type 0x100
    end

    class Severity < Number
      type 0x101
    end

  end
end
