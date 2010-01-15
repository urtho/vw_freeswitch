# Include hook code here
require 'menu_manager'

menu_item = MenuItem.new
menu_item.top_menu = { :name => 'FreeSwitch' }
menu_item.sub_menus = [
  { :name => 'Configurations', :id => 'fs_configurations', :controller => 'fs_configuration', :additional_controllers => [ 'fs_extension' ] },
  { :name => 'Announcements', :id => 'fs_prompts', :controller => 'fs_prompts' },
]

MenuManager.add_item menu_item
