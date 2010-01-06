class FsDialplanController < ApplicationController
  
  def index
     dialplan
     respond_to do |type|
       type.xml { render :action => "dialplan.rxml", :layout => false}
     end
  end
   
  def dialplan
     @fs_configuration = FsConfiguration.find(:first, :conditions => ['active'])
  end
    
end
