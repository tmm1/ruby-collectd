module Collectd
  ##
  # Included by Interface
  module ProcStats
    def process_status(field)
      fields = {}
      begin
        IO.readlines("/proc/#{$$}/status").each { |line|
          line.strip!
          if line =~ /^(.+?):\s+(.+)$/
            fields[$1] = $2
          end
        }
      rescue Errno::ENOENT
        nil
      else
        fields[field]
      end
    end

    def with_polled_memory
      memory('VmRSS').polled_gauge do
        v = process_status('VmRSS') ? v.to_i * 1024 : nil
      end
      memory('VmSize').polled_gauge do
        v = process_status('VmSize') ? v.to_i * 1024 : nil
      end

      self
    end

    def with_polled_cpu
      cpu('user').polled_counter do
        (Process::times.utime * 100).to_i
      end
      cpu('system').polled_counter do
        (Process::times.stime * 100).to_i
      end
    end

    def with_full_proc_stats
      with_polled_memory
      with_polled_cpu
    end
  end
end
