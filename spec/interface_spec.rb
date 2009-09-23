$: << File.dirname(__FILE__) + '/../lib'
require 'collectd'

describe Collectd do
  before(:each) do
    @server = mock('Server')
    Collectd << @server
  end
  after(:each) do
    Collectd.reset!
  end

  it 'should set_counter' do
    @server.should_receive(:set_counter).
      with([:plugin1, :plugin_instance1,
            :type1, :type_instance1], [23])
    Collectd.plugin1(:plugin_instance1).type1(:type_instance1).counter = 23
  end
  it 'should inc_counter' do
    @server.should_receive(:inc_counter).
      with([:plugin1, :plugin_instance1,
            :type1, :type_instance1], [23, 42])
    Collectd.plugin1(:plugin_instance1).type1(:type_instance1).count! 23, 42
  end
  it 'should set_gauge' do
    @server.should_receive(:set_gauge).
      with([:plugin1, :plugin_instance1,
            :type1, :type_instance1], [23, 42, 5])
    Collectd.plugin1(:plugin_instance1).type1(:type_instance1).gauge = [23, 42, 5]
  end

  it 'should poll a pollable' do
    pollable = mock('Pollable')
    Collectd.add_pollable { |*a|
      pollable.call *a
    }
    pollable.should_receive(:call).with(@server).and_return(nil)
    Collectd.run_pollables_for @server
  end
  it 'should poll a polled_count' do
    Collectd.plugin1(:plugin_instance1).type1(:type_instance1).polled_count do
      [23, 42, 5, 7]
    end
    @server.should_receive(:inc_counter).
      with([:plugin1, :plugin_instance1,
            :type1, :type_instance1], [23, 42, 5, 7])
    Collectd.run_pollables_for @server
  end
  it 'should poll a polled_counter' do
    Collectd.plugin1(:plugin_instance1).type1(:type_instance1).polled_counter do
      [23, 42, 5, 7]
    end
    @server.should_receive(:set_counter).
      with([:plugin1, :plugin_instance1,
            :type1, :type_instance1], [23, 42, 5, 7])
    Collectd.run_pollables_for @server
  end
  it 'should poll a polled_gauge' do
    Collectd.plugin1(:plugin_instance1).type1(:type_instance1).polled_gauge do
      [23, 42, 5, 7]
    end
    @server.should_receive(:set_gauge).
      with([:plugin1, :plugin_instance1,
            :type1, :type_instance1], [23, 42, 5, 7])
    Collectd.run_pollables_for @server
  end
end

class StubServer < Collectd::Values
  attr_reader :counters
  attr_reader :gauges
  def initialize
    super(1000)
  end
end

describe Collectd::ProcStats do
  before(:each) do
    @server = StubServer.new
    Collectd << @server
    Collectd.plugin1(:plugin_instance1).with_full_proc_stats
    Collectd.run_pollables_for @server
  end
  after(:each) do
    Collectd.reset!
  end

  context 'when polling memory' do
    it 'should report VmRSS' do
      g = @server.gauges[[:plugin1, :plugin_instance1, :memory, "VmRSS"]]
      g[0].should be_kind_of(Fixnum)
    end
    it 'should report VmSize' do
      g = @server.gauges[[:plugin1, :plugin_instance1, :memory, "VmSize"]]
      g[0].should be_kind_of(Fixnum)
    end
  end
  context 'when polling cpu' do
    it 'should report user time' do
      c = @server.counters[[:plugin1, :plugin_instance1, :cpu, "user"]]
      c[0].should be_kind_of(Fixnum)
    end
    it 'should report system time' do
      c = @server.counters[[:plugin1, :plugin_instance1, :cpu, "system"]]
      c[0].should be_kind_of(Fixnum)
    end
  end
end

describe Collectd::EmPlugin do
  before(:each) do
    @server = StubServer.new
    Collectd << @server
    @df = EM::DefaultDeferrable.new
    Collectd.plugin1(:plugin_instance1).track_deferrable('df', @df)
  end
  after(:each) do
    Collectd.reset!
  end

  context 'when succeeding' do
    it 'should callback' do
      @df.succeed
    end
    it 'should report latency' do
      @df.succeed
      g = @server.gauges[[:plugin1, :plugin_instance1, :latency, 'df_success']]
      g[0].should be_kind_of(Numeric)
    end
    it 'should increase a counter' do
      @df.succeed
      c = @server.counters[[:plugin1, :plugin_instance1, :counter, 'df_success']]
      c[0].should be_kind_of(Numeric)
    end
  end
  context 'when failing' do
    it 'should callback' do
      @df.fail
    end
    it 'should report latency' do
      @df.fail
      g = @server.gauges[[:plugin1, :plugin_instance1, :latency, 'df_error']]
      g[0].should be_kind_of(Numeric)
    end
    it 'should increase a counter' do
      @df.fail
      c = @server.counters[[:plugin1, :plugin_instance1, :counter, 'df_error']]
      c[0].should be_kind_of(Numeric)
    end
  end
end

describe Collectd::Server do
  before :all do
    Collectd.add_server(0.1)
  end
  after :all do
    Collectd.reset!
  end

  it "should spawn a Collectd::Server" do
    servers = []
    Collectd.each_server { |s| servers << s }
    servers.length.should == 1
    servers[0].should be_kind_of(Collectd::Server)
  end

  it "should run for 2 seconds" do
    sleep 2
  end
end

describe Collectd::EmServer do
  it "should spawn a Collectd::Server" do
    EM.run {
      Collectd.add_server 0.1
      EM.next_tick {
        EM.stop
        servers = []
        Collectd.each_server { |s| servers << s }
        servers.length.should == 1
        servers[0].should be_kind_of(Collectd::EmServer)
        Collectd.reset!
      }
    }
  end

  it "should run for 2 seconds" do
    EM.run {
      Collectd.add_server 0.1
      EM::Timer.new(2) {
        EM.stop
        Collectd.reset!
      }
    }
  end
end if defined?(EM)
