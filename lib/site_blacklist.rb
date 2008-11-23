module SiteBlacklist
  
  # Do some stuff when this module is included:
  # - Initialize the plugin's class methods
  # - Add the before_filter
  def self.included(controller)
    controller.extend(ClassMethods)
    controller.load_blacklist_config
    controller.before_filter(:check_site_blacklist)
  end

  # A module of class methods that we'll include in the controller's class
  module ClassMethods
    
    #
    # The configuration method that will be called by the Controller,
    # to set the response to a blacklisted site
    #
    def blacklisted_site_response(method=nil, &block)
      write_inheritable_attribute(:blacklisted_site_response_method, method)
      write_inheritable_attribute(:blacklisted_site_response_block, block)
    end
    
    #
    # Accessor methods
    #
    def blacklisted_site_response_method
      read_inheritable_attribute(:blacklisted_site_response_method)
    end
    def blacklisted_site_response_block
      read_inheritable_attribute(:blacklisted_site_response_block)
    end
    def site_blacklist
      read_inheritable_attribute(:site_blacklist)
    end
    
    # Loader method that reads config/site_blacklist.yml
    def load_blacklist_config
      require 'yaml'
  
      config_file_path = [RAILS_ROOT, 'config', 'site_blacklist.yml'].join('/')
      RAILS_DEFAULT_LOGGER.info "Loading SiteBlacklist Config: #{config_file_path}"

      config_file = File.open( config_file_path )
      
      yaml = YAML::load( config_file )
      yaml = {} if yaml.nil?
      sites = yaml['blacklist'] || []
      _site_blacklist = {:blacklisted_sites=>[], :blacklist_tests=>[]}
      sites.each do |site|
        if site.match(/^\/.*\/$/)
          _site_blacklist[:blacklist_tests].push site.gsub('/','')
        else
          _site_blacklist[:blacklisted_sites].push site
        end
      end
      write_inheritable_attribute(:site_blacklist, _site_blacklist)
    end
  end

  protected
  
  # Check if the given site is blacklisted
  def site_blacklisted?(site)
    
    self.class.site_blacklist[:blacklisted_sites].each do |listed_site|
      if listed_site == site
        @_blacklist_entry = site
        return true
      end
    end

    self.class.site_blacklist[:blacklist_tests].each do |match_to|
      if site.match(match_to)
        @_blacklist_entry = match_to
        return true
      end
    end
    
    return false
  end
  
  # Respond to a blacklisted site
  def respond_to_blacklisted_site!(site, blacklist_entry)
    method = self.class.blacklisted_site_response_method
    block = self.class.blacklisted_site_response_block
    
    self.send(method, site, blacklist_entry) if not method.nil?
    
    if not block.nil?        
      block.bind(self).call(site, blacklist_entry)
    end
  end
  
  private
  
  # This is the before_filter callback
  def check_site_blacklist
    site = request.env['SERVER_NAME'] || ''
    
    if site_blacklisted?(site)
      respond_to_blacklisted_site!(site, @_blacklist_entry)
      return false
    end
    
    return true
  end
end
