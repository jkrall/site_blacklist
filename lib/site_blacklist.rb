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
    def blacklisted_site_response(method=nil, &block)
      @blacklisted_site_response_method = method
      @blacklisted_site_response_block = block
    end
    
    def blacklisted_site_response_method
      @blacklisted_site_response_method
    end
    def blacklisted_site_response_block
      @blacklisted_site_response_block
    end
    def site_blacklist
      @site_blacklist
    end
    
    def load_blacklist_config
      require 'yaml'
  
      config_file_path = [RAILS_ROOT, 'config', 'site_blacklist.yml'].join('/')
      config_file = File.open( config_file_path )
      
      yaml = YAML::load( config_file )
      yaml = {} if yaml.nil?
      sites = yaml['blacklist'] || []
      @site_blacklist = {:blacklisted_sites=>[], :blacklist_tests=>[]}
      sites.each do |site|
        if site.match(/^\/.*\/$/)
          @site_blacklist[:blacklist_tests].push site.gsub('/','')
        else
          @site_blacklist[:blacklisted_sites].push site
        end
      end
    end
  end

  protected
  
  # 
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
  
  def respond_to_blacklisted_site!(site, blacklist_entry)
    method = self.class.blacklisted_site_response_method
    block = self.class.blacklisted_site_response_block
    
    self.send(method, site, blacklist_entry) if not method.nil?
    
    if not block.nil?        
      block.call(site, blacklist_entry)
    end
  end
  
  private
  
  def check_site_blacklist
    site = request.env['SERVER_NAME']
    
    if site_blacklisted?(site)
      respond_to_blacklisted_site!(site, @_blacklist_entry)
      return false
    end
    
    return true
  end
end
