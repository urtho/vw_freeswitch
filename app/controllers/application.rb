require "application_base"
ActiveRecord::Base.class_eval { include ActiveRecord::Acts::Telcobridges }

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_WebOAMP_session_id'
  
  helper :all # include all helpers, all the time

  ROOT_LEVEL = 0
  
  before_filter :instantiate_controller_and_action_names
  before_filter :invalidate_session
  
  class CustomNotFoundError
  end

  def rescue_404
    rescue_action_in_public CustomNotFoundError.new
  end
  
  def rescue_action_in_public(exception)
    case exception
    
    when CustomNotFoundError, ::ActionController::UnknownAction
        render :template => "exception/404", :layout => "telcobridges", :status => "404"
    
    when /Can't connect to MySQL/, /No connection could be made/
      @message = exception
      begin
        using_status true do
          render :template  => 'exception/db_down', :layout => "telcobridges", :status => "500"
        end
      rescue
        puts $!
        @message = exception
        render :template => "exception/default", :layout => "telcobridges", :status => "500"
      end
    
    else
      @message = exception
      render :template => "exception/default", :layout => "telcobridges", :status => "500"
    end
  end

  def local_request?
    return false
  end

  def get_current_config()
    Configuration.find( session[:current_cfg_id] )
  end
  
  def get_current_adapter()
    VirtualAdapter.find( session[:current_adapter_id] ) rescue nil
  end

protected  
  def instantiate_controller_and_action_names
    @current_action = action_name
    @current_controller = controller_name
  end
  
  def invalidate_session
    stored_pid = session[:pid]
    if stored_pid.nil?
      session[:pid] = Process.pid
    elsif stored_pid != Process.pid
      reset_session
    end
  end

  def login_required
    if session[:auth] 
      yield 
    else
      flash[:notice] = 'You must login first.'
      render(:template => '/login/index')
    end
  end

  def get_current_gw_port()
    gw_port = nil
    current_system = nil
    if params[:controller] == 'system_info' || params[:controller] == 'status'
      current_system = SystemInfo.find params[:id]
    elsif get_current_config && get_current_config.active_system_info
      current_system = get_current_config.active_system_info
    end
    gw_port = current_system.gw_port if current_system
    gw_port
  end

  def using_status( use_active_gw_port = false )
    options = {}
    unless use_active_gw_port
      gw_port = get_current_gw_port
      options = { :gw_port => gw_port }
    end

    @status_svc = StatusClient.new( options )
    if !@status_svc.started?
      flash[:notice] = 'Status is not available for the current configuration'
    end
    yield 
	unless @status_svc.class.error.empty?
      logger.error @status_svc.class.error
      @status_svc.class.error = ''
    end
    @status_svc.garbage_collect
  end

  def using_routing
    @routing_svc = RoutingClient.new
    yield
  end
    
  def root_level_required
    if session[:auth].write_privilege_level == ROOT_LEVEL 
      yield
    else
      flash[:notice] = 'You must have super-user access.'
      render(:template => '/login/index')
    end
  end
    
  def config_required
    if get_current_config
      yield
    else
      flash[:notice] = 'You must choose a configuration.'
      redirect_to(:controller => 'configuration')
    end
  end
  
  def adapter_required
    if get_current_adapter
      yield
    else
      flash[:notice] = 'You must choose an adapter.'
      redirect_to(:controller => 'virtual_adapter')
    end
  end
  
  def check_read_privilege( privilege )
    if privilege < session[:auth].read_privilege_level 
      flash[:notice] = 'You do not have permission.'
      render(:template => '/login/index')
      false
    else
      true
    end
  end
  
  def check_write_privilege( privilege )
    production_system_cfg = false

	if respond_to? 'object_configuration'
      config = object_configuration
    else
      config = get_current_config
    end
    
    # Check if a certain config is on an active production system
    SystemInfo.find_all_by_active_configuration_id(config).each do |system|
      if system.lock_active_configuration
        production_system_cfg = true
        break
      end
    end
    
    if privilege < session[:auth].write_privilege_level || production_system_cfg
      flash[:notice] = 'You do not have permission.'
      if request.get?
        render(:template => '/login/index')
      else
        render :inline => 'You do not have permission.'
      end
      false
    else
      true
    end
  end
  
  def check_write_permissions
    check_write_privilege object_privilege_level
  end

  def check_read_permissions
    check_read_privilege object_privilege_level
  end

  
  def set_current_config( config )
    if config
      set_current_adapter( config.virtual_adapters.find(:first) ) if config.id != session[:current_cfg_id]
      session[:current_cfg_id] = config.id
    else
      flash[:notice] = "No configuration found, you must create one to continue."
      session[:current_cfg_id] = nil
    end
  end
  
  def find_first_active_config
    first_active_configuration = nil
    Configuration.find(:all, :conditions => [ "privilege_level >= ?", session[:auth].read_privilege_level.to_s]).each do |configuration|
      if configuration.active_system_info
        first_active_configuration = configuration
        break
      end
    end

    unless first_active_configuration
      Configuration.find(:first, 
          :conditions => [ "privilege_level >= ?", session[:auth].read_privilege_level.to_s])
    end

    first_active_configuration
  end
  
  def set_current_adapter( adapter )
    if adapter
      session[:current_cfg_id] = adapter.configuration.id
      session[:current_adapter_id] = adapter.id
    else
      flash[:notice] = "No adapter found, you must create one to continue."
      session[:current_adapter_id] = nil
    end
  end
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'fb2f9c79d7e7c44a1a79905740641147'
end
