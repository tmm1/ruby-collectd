# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{collectd}
  s.version = "0.0.12"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Stephan Maka"]
  s.date = %q{2009-09-23}
  s.email = %q{astro@spaceboyz.net}
  s.files = [
     "Rakefile",
     "VERSION.yml",
     "examples/em_sender.rb",
     "examples/sender.rb",
     "lib/collectd.rb",
     "lib/collectd/em_server.rb",
     "lib/collectd/em_support.rb",
     "lib/collectd/interface.rb",
     "lib/collectd/pkt.rb",
     "lib/collectd/proc_stats.rb",
     "lib/collectd/server.rb",
     "spec/interface_spec.rb"
  ]
  s.homepage = %q{http://github.com/astro/ruby-collectd}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Send collectd statistics from Ruby}
  s.test_files = [
    "spec/interface_spec.rb",
     "examples/sender.rb",
     "examples/em_sender.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
