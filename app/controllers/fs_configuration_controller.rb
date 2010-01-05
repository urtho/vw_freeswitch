class FsConfigurationController < ApplicationController
#  around_filter :login_required
  
  before_filter :find_db_obj, :except => [ :index, :list, :new, :create, :help, :dialplan, :status, :clear_hits ]
  
  layout "telcobridges"

  def index
    list
    render :action => 'list'
  end

  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @fs_configurations = FsConfiguration.find(:all, :page => {:size => 16, :current => params[:page]})
  end

  def new
    @fs_configuration = FsConfiguration.new
  end

  def create
    @fs_configuration = FsConfiguration.new(params[:fs_configuration])
    
    begin
    @fs_configuration.transaction do      
      @fs_configuration.save!
      flash[:notice] = 'FreeSwitch configuration was successfully created.'
      redirect_to :action => 'edit', :id => @fs_configuration
    end
    rescue
      flash[:error] = "FreeSwitch configuration creation failed: #{$!}"
      render :action => 'new'
    end
  end
  
  def activate
    a = FsConfiguration.first(:conditions => ['active'])
    a.active = 0
    @fs_configuration.active = 1
    a.transaction do
      a.save!
      @fs_configuration.save!
    end
    redirect_to :action => 'list'
    #@fs_configuration.commit
  end

  def edit
  end

  def help
  end
  
  def dialplan
    @fs_configurations = FsConfiguration.all(:conditions => ['active'])
    respond_to do |type|
      type.xml { render :action => "dialplan.rxml", :layout => false}
    end
  end

  def update
    begin
    @fs_configuration.transaction do
      @fs_configuration.update_attributes!(params[:fs_configuration])    
      flash[:notice] = 'FreeSwitch configuration was successfully updated.'
      redirect_to :action => 'list'
    end
    rescue
      flash[:error] = "FreeSwitch configuration update failed: #{$!}"
      render :action => 'edit'
    end
  end
  
  def destroy
    @fs_configuration.destroy    
    redirect_to :action => 'list'
  end
  
  def status
    @fs_configuration = FsConfiguration.find(:first, :conditions => ["active"])
    @fs_status_primary = @fs_configuration.get_fs_status('localhost')
    @fs_ext_hits = @fs_configuration.get_ext_hits('localhost')
  end
  
  def clear_hits
    FsConfiguration.find(:first, :conditions => ["active"]).clear_ext_hits('localhost')
    redirect_to :action => 'status'
  end
  
  def clone_cfg
    @fs_cfg_copy = @fs_configuration.clone :include => :fs_extensions, :except => [:id, :name, :active, :commited]
    @fs_cfg_copy.name = @fs_configuration.name + "_copy"
    @fs_cfg_copy.active = 0
    @fs_cfg_copy.commited = 0
    @fs_cfg_copy.save!
    redirect_to :action => 'list'
  end
  
private
  def find_db_obj() 
    begin
      @fs_configuration = FsConfiguration.find(params[:id])
    rescue
      raise
      flash[:error] = "FsConfiguration id '#{params[:id]}' does not exist."
      redirect_to :action => :list
    end
  end
end
