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
      cpu('user').polled_counter do
        (Process::times.utime * 100).to_i
      end
      cpu('sys').polled_counter do
        (Process::times.stime * 100).to_i
      end
    end

    def with_full_proc_stats
      with_polled_memory
      with_polled_cpu
    end
  end
end
