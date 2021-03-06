#--
# Copyright (c) 2009-2010 Novell, Inc.
# 
# All Rights Reserved.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
# 
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#++

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'mocha'

require 'rexml/document'


def test_data(name)
  File.join(File.dirname(__FILE__), '..', 'data', name)
end

class MetricTest < ActiveSupport::TestCase

  PARSE_CONFIG_1 ={"Network"=>{"y_scale"=>1, "y_label"=>"MByte", "single_graphs"=>[{"lines"=>[{"label"=>"received", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"rx", "metric_id"=>"interface+if_packets-eth0"}, {"label"=>"sent", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"tx", "metric_id"=>"interface+if_packets-eth0"}], "headline"=>"Network", "cummulated"=>"false", "linegraph"=>"false"}]}, "CPU"=>{"y_scale"=>1, "y_label"=>"Percent", "single_graphs"=>[{"lines"=>[{"label"=>"Idle", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>"cpu-0+cpu-idle"}, {"label"=>"Used", "limits"=>{"max"=>"10", "min"=>"0"}, "metric_id"=>"cpu-0+cpu-user"}], "headline"=>"CPU", "cummulated"=>"false", "linegraph"=>"false"}]}, "Disk"=>{"y_scale"=>1073741824, "y_label"=>"GByte", "single_graphs"=>[{"lines"=>[{"label"=>"used", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"used", "metric_id"=>"df+df-root"}, {"label"=>"free", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"free", "metric_id"=>"df+df-root"}], "headline"=>"root", "cummulated"=>"true", "linegraph"=>"false"}]}, "Memory"=>{"y_scale"=>1048567, "y_label"=>"MByte", "single_graphs"=>[{"lines"=>[{"label"=>"Used", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>"memory+memory-used"}, {"label"=>"Free", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>"memory+memory-free"}, {"label"=>"Cached", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>"memory+memory-cached"}], "headline"=>"Memory", "cummulated"=>"true", "linegraph"=>"false"}]}}


  def setup
    # standard setup
    Metric.stubs(:this_hostname).returns('myhost.domain.de')
    Metric.stubs(:available_hosts).returns(['foo.com', 'myhost.domain.de'])
    Metric.stubs(:rrd_files).returns(['/var/lib/collectd/foo.com/cpu-0/cppudata-1.rrd', '/var/lib/collectd/myhost.domain.de/memory/memory-free.rrd', '/var/lib/collectd/myhost.domain.de/cpu-1/cpudata-1.rrd', '/var/lib/collectd/myhost.domain.de/cpu-1/cpudata-2.rrd', '/var/lib/collectd/myhost.domain.de/cpu-2/cpudata-1.rrd', '/var/lib/collectd/myhost.domain.de/interface/packets.rrd', '/var/lib/collectd/myhost.domain.de/interface/some-0.rrd'])
    Metric.stubs(:collectd_runnning?).returns(true)
    Graph.stubs(:parse_config).returns(PARSE_CONFIG_1)
  end

  def teardown
  end
  
  def test_default_host
    # if only one host data is available, then that one should be
    # the one used for the data directory
    Metric.stubs(:this_hostname).returns(nil)
    assert_equal 'foo.com', Metric.default_host
    
    Metric.stubs(:this_hostname).returns('myhost.domain.de')
    assert_equal 'myhost.domain.de', Metric.default_host
  end

  def test_parse_rrdtool_output
    stop = Time.now
    start = Time.now - 300

    Metric.stubs(:run_rrdtool).with('/var/lib/collectd/myhost.domain.de/memory/memory-free.rrd', :start => start, :stop => stop).returns(File.open(test_data('rrdtool-memory-free.txt')).read)
    Metric.stubs(:run_rrdtool).with('/var/lib/collectd/myhost.domain.de/interface/packets.rrd', :start => start, :stop => stop).returns(File.open(test_data('rrdtool-packets.txt')).read)

    ret = Metric.find(:all, :plugin => /memory/, :type => 'memory', :type_instance => 'free')
    memory = ret.first

    expected = { "value"=>
      {Time.at(1252071700) =>"6.1514301440e+08".to_f,
      Time.at(1252071690) =>"6.1518643200e+08".to_f,
      Time.at(1252071680) =>"6.1513154560e+08".to_f,
      Time.at(1252071780) => nil,
      Time.at(1252071670) =>"6.1510287360e+08".to_f,
      Time.at(1252071770) => nil,
      Time.at(1252071660) =>"6.1664133120e+08".to_f,
      Time.at(1252071750) =>"6.1545021440e+08".to_f,
      Time.at(1252071760) =>"6.1678837760e+08".to_f},
      
      "interval" => 10,
      "starttime" => Time.at(1252071660) }
    
    assert_equal expected, memory.data(:start => start, :stop => stop)

    ret = Metric.find(:all, :plugin => /interface/, :type => 'packets')
    packets = ret.first
    expected =  {"tx"=>
     {Time.at(1252075780) => "4.2576000000e+02".to_f,
      Time.at(1252075770) => "1.5922000000e+02".to_f,
      Time.at(1252075760) => "6.1660000000e+01".to_f,
      Time.at(1252075500) => "7.7900000000e+00".to_f,
      Time.at(1252075790) => nil,
      Time.at(1252075800) => nil},
    "rx"=>
     {Time.at(1252075780) => "2.8069000000e+02".to_f,
      Time.at(1252075770) => "3.3962000000e+02".to_f,
      Time.at(1252075760) => "2.5814000000e+02".to_f,
      Time.at(1252075500) => "2.2150000000e+01".to_f,
      Time.at(1252075790) => nil,
      Time.at(1252075800) => nil},
      "interval"=>10,
      "starttime"=>Time.at(1252075500)}
    
    assert_equal expected, packets.data(:start => start, :stop => stop)    
    
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.metric do
      xml.id "myhost*domain*de+interface+packets"
      xml.identifier "myhost.domain.de/interface/packets"
      xml.host "myhost.domain.de"
      xml.plugin "interface"
      xml.plugin_instance ""
      xml.type "packets"
      xml.type_instance ""

      xml.value(:interval => "10", :column => "tx", :start=>"1252075500", :type => :hash ) do
        xml.value '"7.79"'
        xml.value '"61.66"'
        xml.value '"159.22"'
        xml.value '"425.76"'
        xml.value '""'
        xml.value '""'
      end

      xml.value(:interval => "10", :column => "rx", :start=>"1252075500", :type => :hash) do
        xml.value '"22.15"'
        xml.value '"258.14"'
        xml.value '"339.62"'
        xml.value '"280.69"'
        xml.value '""'
        xml.value '""'
      end
    end
    ptx = packets.to_xml(:data => packets.data(:start => start, :stop => stop))
#    puts "       "
#    puts "packets.to_xml #{ptx.inspect}"
    xtg = xml.target!
#    puts "    xml.target #{xtg.inspect}"    
    assert = Hash.from_xml(xtg).diff(Hash.from_xml(ptx)).size == 0
  end

  def test_finders
    ret = Metric.find(:all)
    assert_equal 7, ret.size
    assert ret.map{|x| x.plugin_full}.include?('cpu-1')
    assert ret.map{|x| x.plugin}.include?('memory')
    assert ret.map{|x| x.plugin}.include?('interface')
    
    ret = Metric.find(:all, :plugin => 'memory')
    assert_equal 1, ret.size
    assert_equal 'memory', ret.first.plugin
    assert_equal 'memory-free', ret.first.type_full
    assert_equal 'myhost.domain.de', ret.first.host

    # should produce same result
    ret = Metric.find(:all, :plugin_full => /memory/)
    assert_equal 1, ret.size
    ret = Metric.find(:all, :plugin_full => /memory/, :type_full => 'boooh')
    assert_equal 0, ret.size
    ret = Metric.find(:all, :plugin_full => /memory/, :type_full => 'memory-free')
    assert_equal 1, ret.size
    
    # test attributes
    assert_equal '/var/lib/collectd/myhost.domain.de/memory/memory-free.rrd', ret.first.path
    assert_equal 'myhost.domain.de/memory/memory-free', ret.first.identifier
    
    ret = Metric.find(:all, :plugin_full => /meemory/)
    assert_equal 0, ret.size

    ret = Metric.find(:all, :plugin_full => 'meemory')
    assert_equal 0, ret.size

    # using a regexp
    ret = Metric.find(:all, :plugin_full => /cpu/)
    assert ret.map{ |x| x.plugin_full }.include?('cpu-1')
    assert ret.map{ |x| x.plugin_full }.include?('cpu-2')
    assert ret.map{ |x| x.type_full }.include?('cpudata-1')
    assert ret.map{ |x| x.type_full }.include?('cpudata-2')
    assert_equal 3, ret.size
  end
  
  
end
