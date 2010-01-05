class FsDialplanController < ApplicationController
  
  def index
     dialplan
     respond_to do |type|
       type.xml { render :action => "dialplan.rxml", :layout => false}
     end
  end
   
  def dialplan
     @fs_configurations = FsConfiguration.all(:conditions => ['active'])
  end
    
end