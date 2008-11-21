if RAILS_ENV == "test"
  require File.join(File.dirname(__FILE__), "lib", "site_blacklist")
end
