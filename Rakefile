begin
  require 'jeweler'
rescue LoadError
  raise "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

Jeweler::Tasks.new do |s|
  s.name = "collectd"
  s.summary = "Send collectd statistics from Ruby"
  s.email = "astro@spaceboyz.net"
  s.homepage = "http://github.com/astro/ruby-collectd"
  s.authors = ["Stephan Maka"]
  s.files =  FileList["[A-Z]*", "{lib,spec,examples}/**/*"]
  #s.add_dependency 'eventmachine'
end

begin
  require 'spec/rake/spectask'
  desc "Run all Spec"
  Spec::Rake::SpecTask.new('spec') do |spec|
    spec.spec_files = FileList['spec/*.rb']
    spec.verbose = true
    spec.warning = true
    spec.rcov = true
    spec.rcov_opts = []
    spec.rcov_opts = ['--exclude', 'spec']
  end
rescue LoadError
  task :spec do
    abort "Rspec is not available. In order to run rspec, you must: sudo gem install rspec"
  end
end
