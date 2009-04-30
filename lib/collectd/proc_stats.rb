module Collectd
  ##
  # Included by Interface
  module ProcStats
    def with_polled_memory
      def process_status(field)
        fields = {}
        IO.readlines("/proc/#{$$}/status").each { |line|
          line.strip!
          if line =~ /^(.+?):\s+(.+)$/
            fields[$1] = $2
          end
        }
        fields[field]
      end

      memory('VmRSS').polled_gauge do
        process_status('VmRSS').to_i * 1024
      end
      memory('VmSize').polled_gauge do
        process_status('VmSize').to_i * 1024
      end

      self
    end

    def with_polled_cpu
      def schedstats
        if IO.readlines("/proc/#{$$}/schedstat").to_s =~ /^(\d+) (\d+) (\d+)/
            [$1.to_i, $2.to_i, $3.to_i]
        else
          []
        end
      end

      cpu('user').polled_counter do
        schedstats[0]
      end
      cpu('wait').polled_counter do
        schedstats[1]
      end
    end

    def with_full_proc_stats
      with_polled_memory
      with_polled_cpu
    end
  end
end
