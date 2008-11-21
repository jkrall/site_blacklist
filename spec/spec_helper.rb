require "rubygems"
require "spec"
# gem install redgreen for colored test output
begin require "redgreen" unless ENV['TM_CURRENT_LINE']; rescue LoadError; end

require "active_support"

silence_warnings do
  require "action_controller"
  require "action_controller/integration"
end

Spec::Runner.configure do |config|
end

require File.expand_path(File.dirname(__FILE__) + "/../lib/site_blacklist")

RAILS_ROOT = File.expand_path(File.dirname(__FILE__))