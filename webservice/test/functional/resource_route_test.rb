#
# test/functional/resource_route_test.rb
#
# This tests route creation from the resource database
#
require 'test_helper'

class TestPlugin
  attr_reader :directory
  def initialize path
    @directory = path
  end
end

class ResourceRouteTest < ActiveSupport::TestCase

  # See http://pennysmalls.com/2009/03/04/rails-23-breakage-and-fixage/
  include ActionController::Assertions::RoutingAssertions
  
  require "lib/resource_registration"
  
  fixtures :domains, :resources
  
  # config/initializers/resource_registration.rb sets it up
  
  test "resource route initialization" do
    
    prefix = "yast"
    
    ResourceRegistration.reset
    plugin = TestPlugin.new "test/resource_fixtures/good"
    ResourceRegistration.register_plugin plugin

#    $stderr.puts ActionController::Routing::Routes.routes
    
    # root URI links to ResourceController.index
    assert_generates "/#{prefix}", :controller => "resource", :action => "index"
    assert_routing( { :path => "/#{prefix}", :method => :get }, { :controller => "resource", :action => "index" } )
    
    # Ensure there is a route for every resource
    ResourceRegistration.resources.each do |interface,implementations|
      implementations.each do |implementation|
	if implementation[:singular]
	  assert_generates "#{implementation[:controller]}", { :controller => "#{implementation[:controller]}", :action => :show }
	else
	  assert_generates "#{implementation[:controller]}", { :controller => "#{implementation[:controller]}", :action => :index }
	end
      end
    end
  end
  
end
