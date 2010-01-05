class FsPromptsController < ApplicationController

  layout "telcobridges"

  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }
         
  def index
    @fs_prompts = FsPrompt.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @fs_prompts }
    end
  end

  def show
    @fs_prompt = FsPrompt.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @fs_prompt }
    end
  end

  def new
    @fs_prompt = FsPrompt.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @fs_prompt }
    end
  end

  def edit
    @fs_prompt = FsPrompt.find(params[:id])
  end

  def create
    @fs_prompt = FsPrompt.new(params[:fs_prompt])

    respond_to do |format|
      if @fs_prompt.save
        flash[:notice] = 'FsPrompt was successfully created.'
        format.html { redirect_to :action => 'index' }
        format.xml  { render :xml => @fs_prompt, :status => :created, :location => @fs_prompt }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @fs_prompt.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @fs_prompt = FsPrompt.find(params[:id])

    respond_to do |format|
      if @fs_prompt.update_attributes(params[:fs_prompt])
        flash[:notice] = 'FsPrompt was successfully updated.'
        format.html { redirect_to :action => "index" }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @fs_prompt.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @fs_prompt = FsPrompt.find(params[:id])
   
    respond_to do |format| 
      if @fs_prompt.destroy
        flash[:notice] = 'Prompt deleted'
        format.html { redirect_to :action => 'index' }
        format.xml  { head :ok }
      else
        flash[:error] = 'Prompt could not be deleted, ' + ActiveRecord::Base.dependent_restrict_error
        format.html { redirect_to :action => 'index' }
        format.xml  { render :xml => @fs_prompt.errors, :status => :unprocessable_entity}
      end
    end
  end
end
