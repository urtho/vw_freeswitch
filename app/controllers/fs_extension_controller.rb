class FsExtensionController < ApplicationController
#  around_filter :login_required

  before_filter :find_db_obj, :except => [ :new, :create ]

  layout "telcobridges"
  
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }


#  def index
#    list   
#    render :action => 'list'
#  end

#  def list
#    @fs_extensions = FsExtension.find(:all, :order => "name ASC", :page => {:size => 16, :current => params[:page]},
#      :order => 'position',
#      :conditions => {:configuration_id => get_current_config})
#  end

  def new
    @fs_extension = FsExtension.new
    if params[:fs_prompt_id]
      @fs_extension.fs_prompt = FsPrompt.find(params[:fs_prompt_id])
    else
      @fs_extension.fs_prompt = @fs_extension.NullPrompt
    end
    @fs_extension.fs_configuration = FsConfiguration.find(params[:fs_configuration_id])
  end

  def create
    @fs_extension = FsExtension.new(params[:fs_extension])

    begin
      @fs_extension.save!
      flash[:notice] = 'FsExtension was successfully created.'
      redirect_to :controller => 'fs_configuration', :action => 'edit', :id => @fs_extension.fs_configuration_id
    rescue
      flash[:error] = 'FsExtension create failed.' + $!
      render :action => 'new'
    end
  end  

  def edit
  end

  def update
    begin   
      @fs_extension.update_attributes!(params[:fs_extension])
      flash[:notice] = 'FsExtension was successfully updated.'
      redirect_to :controller => 'fs_configuration', :action => 'edit', :id => @fs_extension.fs_configuration_id
    rescue
      flash[:error] = 'FsExtension update failed.' + $!
      render :action => 'edit'
    end
  end  

  def destroy
    FsExtension.find(params[:id]).destroy
    redirect_to :controller => 'fs_configuration', :action => 'edit', :id => @fs_extension.fs_configuration_id
  end

  def move_higher
    @fs_extension.move_higher
    redirect_to :controller => 'fs_configuration', :action => 'edit', :id => @fs_extension.fs_configuration_id
  end

  def move_lower
    @fs_extension.move_lower
    redirect_to :controller => 'fs_configuration', :action => 'edit', :id => @fs_extension.fs_configuration_id
  end

  def move_to_bottom
    @fs_extension.move_to_bottom
    redirect_to :controller => 'fs_configuration', :action => 'edit', :id => @fs_extension.fs_configuration_id
  end

  def move_to_top
    @fs_extension.move_to_top
    redirect_to :controller => 'fs_configuration', :action => 'edit', :id => @fs_extension.fs_configuration_id
  end
  
  def activate
    @fs_extension.active = 1
    @fs_extension.save!
    flash[:notice] = 'FsExtension was successfully activated.'
    redirect_to :controller => 'fs_configuration', :action => 'edit', :id => @fs_extension.fs_configuration_id
  end
  
  def deactivate
    @fs_extension.active = 0
    @fs_extension.save!
    flash[:notice] = 'FsExtension was successfully deactivated.'
    redirect_to :controller => 'fs_configuration', :action => 'edit', :id => @fs_extension.fs_configuration_id
  end

private
  def find_db_obj
    begin
      @fs_extension = FsExtension.find(params[:id])
    rescue
      flash[:error] = "FsExtension id '#{params[:id]}' does not exist." + $!
      redirect_to :controller => 'fs_configuration', :action => 'list'
    end
  end  
#  def object_privilege_level
#    return get_current_config.privilege_level unless @fs_extension
#    @fs_extension.configuration.privilege_level 
#  end
#  helper_method :object_privilege_level

end
