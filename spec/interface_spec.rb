$: << File.dirname(__FILE__) + '/../lib'
require 'collectd'

describe Collectd do
  before(:each) do
    Collectd.reset!
    @server = mock('Server')
    Collectd << @server
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
    Collectd.reset!
    @server = StubServer.new
    Collectd << @server
    Collectd.plugin1(:plugin_instance1).with_full_proc_stats
    Collectd.run_pollables_for @server
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
    if File.exist?("/proc/#{$$}/schedstat")
      it 'should report user time' do
        c = @server.counters[[:plugin1, :plugin_instance1, :cpu, "user"]]
        c[0].should be_kind_of(Fixnum)
      end
      it 'should report wait time' do
        c = @server.counters[[:plugin1, :plugin_instance1, :cpu, "wait"]]
        c[0].should be_kind_of(Fixnum)
      end
    else
      it 'when not available here' do
        pending('not available here')
      end
    end
  end
end

describe Collectd::EmPlugin do
  before(:each) do
    Collectd.reset!
    @server = StubServer.new
    Collectd << @server
    @df = EM::DefaultDeferrable.new
    Collectd.plugin1(:plugin_instance1).track_deferrable('df', @df)
  end

  context 'when succeeding' do
    it 'should callback' do
      @df.succeed
    end
    it 'should report latency' do
      @df.succeed
      g = @server.gauges[[:plugin1, :plugin_instance1, :latency, 'df success']]
      g[0].should be_kind_of(Numeric)
    end
    it 'should increase a counter' do
      @df.succeed
      c = @server.counters[[:plugin1, :plugin_instance1, :counter, 'df success']]
      c[0].should be_kind_of(Numeric)
    end
  end
  context 'when failing' do
    it 'should callback' do
      @df.fail
    end
    it 'should report latency' do
      @df.fail
      g = @server.gauges[[:plugin1, :plugin_instance1, :latency, 'df error']]
      g[0].should be_kind_of(Numeric)
    end
    it 'should increase a counter' do
      @df.fail
      c = @server.counters[[:plugin1, :plugin_instance1, :counter, 'df error']]
      c[0].should be_kind_of(Numeric)
    end
  end
end
