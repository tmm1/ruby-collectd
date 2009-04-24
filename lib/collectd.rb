require 'collectd/interface'
require 'collectd/server'
begin
  require 'collectd/em_server'
rescue LoadError
  # EM is optional
end


