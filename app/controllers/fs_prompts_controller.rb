class FsPromptsController < ApplicationController

  layout "telcobridges"
  # GET /fs_prompts
  # GET /fs_prompts.xml
  def index
    @fs_prompts = FsPrompt.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @fs_prompts }
    end
  end

  # GET /fs_prompts/1
  # GET /fs_prompts/1.xml
  def show
    @fs_prompt = FsPrompt.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @fs_prompt }
    end
  end

  # GET /fs_prompts/new
  # GET /fs_prompts/new.xml
  def new
    @fs_prompt = FsPrompt.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @fs_prompt }
    end
  end

  # GET /fs_prompts/1/edit
  def edit
    @fs_prompt = FsPrompt.find(params[:id])
  end

  # POST /fs_prompts
  # POST /fs_prompts.xml
  def create
    @fs_prompt = FsPrompt.new(params[:fs_prompt])

    respond_to do |format|
      if @fs_prompt.save
        flash[:notice] = 'FsPrompt was successfully created.'
        format.html { redirect_to(@fs_prompt) }
        format.xml  { render :xml => @fs_prompt, :status => :created, :location => @fs_prompt }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @fs_prompt.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /fs_prompts/1
  # PUT /fs_prompts/1.xml
  def update
    @fs_prompt = FsPrompt.find(params[:id])

    respond_to do |format|
      if @fs_prompt.update_attributes(params[:fs_prompt])
        flash[:notice] = 'FsPrompt was successfully updated.'
        format.html { redirect_to(@fs_prompt) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @fs_prompt.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /fs_prompts/1
  # DELETE /fs_prompts/1.xml
  def destroy
    @fs_prompt = FsPrompt.find(params[:id])
    @fs_prompt.destroy

    respond_to do |format|
      format.html { redirect_to(fs_prompts_url) }
      format.xml  { head :ok }
    end
  end
end
