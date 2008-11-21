require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require 'ostruct'

describe "when loading the config file" do

  class FakeController < ActionController::Base
    include SiteBlacklist
  end

  before(:each) do
    File.stub!(:open).and_return(mock("config_file"))
    YAML.stub!(:load).and_return({})
  end
    
  it "should load the yml file from RAILS_ROOT/config/site_blacklist.yml" do
    File.should_receive(:open).with([RAILS_ROOT, 'config', 'site_blacklist.yml'].join('/')).and_return(mock("config_file"))      
    FakeController.load_blacklist_config
  end
  
  it "should add the before_filter" do
    FakeController.filter_chain[0].method.should == :check_site_blacklist
  end

  describe "when storing the site list" do
    it "should store a empty hash for the :blacklist key" do
      YAML.stub!(:load).and_return({'blacklist'=>[]})
      FakeController.load_blacklist_config        
      FakeController.site_blacklist[:blacklisted_sites].should == []
      FakeController.site_blacklist[:blacklist_tests].should == []
    end

    it "should store an ordinary site listing in the :blacklisted_sites array" do
      YAML.stub!(:load).and_return({'blacklist'=>['test.host', 'foo.bar']})
      FakeController.load_blacklist_config                
      FakeController.site_blacklist[:blacklisted_sites].should == ['test.host', 'foo.bar']
    end

    it "should store a site match regex listing in the :blacklist_tests array" do
      YAML.stub!(:load).and_return({'blacklist'=>['/.*\.host/', '/.*bar$/']})
      FakeController.load_blacklist_config                
      FakeController.site_blacklist[:blacklist_tests].should == ['.*\.host', '.*bar$']
    end
  end
end

describe "when processing a request through the filter" do
  before(:each) do
    FakeController.stub!(:request).and_return(OpenStruct.new(:env=>{'SERVER_NAME'=>'theplanet.com'}))
  end
  
  describe "when the requesting server is blacklisted" do
    it "should check if the site is blacklisted, and return false" do
      f = FakeController.new      
      f.stub!(:request).and_return(OpenStruct.new(:env=>{'SERVER_NAME'=>'theplanet.com'}))
      f.should_receive(:site_blacklisted?).with('theplanet.com').and_return(true)
      f.stub!(:respond_to_blacklisted_site!)
      f.send(:check_site_blacklist).should == false
    end
    
    it "should check the :blacklisted_sites list" do
      blacklist = {:blacklisted_sites=>['theplanet.com', 'foo.bar'], :blacklist_tests=>[]}
      FakeController.stub!(:site_blacklist).and_return(blacklist)
      f = FakeController.new
      f.send(:site_blacklisted?,'theplanet.com').should == true
    end
    it "should check for a match in the :blacklist_tests list" do
      blacklist = {:blacklisted_sites=>[], :blacklist_tests=>['.*planet.com', 'foo.*']}
      FakeController.stub!(:site_blacklist).and_return(blacklist)
      f = FakeController.new
      f.send(:site_blacklisted?,'theplanet.com').should == true
    end
    
    it "should call the response method" do
      FakeController.should_receive(:blacklisted_site_response_method).and_return(:test)
      FakeController.should_receive(:blacklisted_site_response_block).and_return(nil)
      f = FakeController.new
      f.should_receive(:test).with('theplanet.com', '.*planet.com')
      f.send(:respond_to_blacklisted_site!,'theplanet.com', '.*planet.com')
    end
    
    it "should call the response block" do
      FakeController.should_receive(:blacklisted_site_response_method).and_return(nil)
      p = Proc.new {}
      FakeController.should_receive(:blacklisted_site_response_block).and_return(p)
      f = FakeController.new
      p.should_receive(:call).with('theplanet.com', '.*planet.com')
      f.send(:respond_to_blacklisted_site!,'theplanet.com', '.*planet.com')
    end
    
  end

  describe "when the requesting server is not blacklisted" do
    it "should check if the site is blacklisted, and return true" do
      f = FakeController.new      
      f.stub!(:request).and_return(OpenStruct.new(:env=>{'SERVER_NAME'=>'theplanet.com'}))
      f.should_receive(:site_blacklisted?).with('theplanet.com').and_return(false)
      f.send(:check_site_blacklist).should == true
    end
    
    it "should check the :blacklisted_sites list" do
      blacklist = {:blacklisted_sites=>['theplanet.com', 'foo.bar'], :blacklist_tests=>[]}
      FakeController.stub!(:site_blacklist).and_return(blacklist)
      f = FakeController.new
      f.send(:site_blacklisted?,'nottheplanet.com').should == false
    end
    it "should check for a match in the :blacklist_tests list" do
      blacklist = {:blacklisted_sites=>[], :blacklist_tests=>['.*planet.com', 'foo.*']}
      FakeController.stub!(:site_blacklist).and_return(blacklist)
      f = FakeController.new
      f.send(:site_blacklisted?,'theplanet.not').should == false
    end
  end

  it "should return the site_blacklist" do
    YAML.stub!(:load).and_return({})
    FakeController.load_blacklist_config                
    FakeController.site_blacklist.should == {:blacklisted_sites=>[], :blacklist_tests=>[]}
  end

  it "should return the blacklisted_site_response_method" do
    YAML.stub!(:load).and_return({})
    FakeController.blacklisted_site_response(:test)    
    FakeController.blacklisted_site_response_method.should == :test
  end
  
  it "should return the blacklisted_site_response_block" do
    YAML.stub!(:load).and_return({})
    p = Proc.new {}
    FakeController.blacklisted_site_response &p
    FakeController.blacklisted_site_response_block.should == p
  end
  
end

