module SiteBlacklist
  
  def self.included(controller)
    load_config
    controller.extend(ClassMethods)
    controller.before_filter(:check_site_blacklist)
  end
  
  module ClassMethods
    def blacklisted_site_response(method=nil, &block)
      write_inheritable_array(:blacklisted_site_response_method, method)
      write_inheritable_array(:blacklisted_site_response_block, &block)      
    end
  end
  
  protected
  
  def site_blacklisted?(site)
    @_blacklist_entry = 'something'
  end
  
  def respond_to_blacklisted_site!(site, blacklist_entry)
    
    method = self.class.read_inheritable_attribute(:blacklisted_site_response_method)
    block = self.class.read_inheritable_attribute(:blacklisted_site_response_block)  
    
    self.send(method, site, blacklist_entry) if not method.nil?
    
    if not block.nil?        
      block.call(site, blacklist_entry)
    end
  end
  
  private
  
  def check_site_blacklist
    
    site = request.referer
    
    if site_blacklisted?(site)
      respond_to_blacklisted_site!(site, @_blacklist_entry)
      return false
    end
    
    return true
  end
  
  @@_blacklist = []
  
  def load_config
    config_file_path = [RAILS_ROOT, 'config', 'site_blacklist.yml'].join('/')
    config_file = File.open( config_file_path )
    
    yaml = YAML::load( config_file )
    p yaml
    @@_blacklist = yaml
  end
  
end
