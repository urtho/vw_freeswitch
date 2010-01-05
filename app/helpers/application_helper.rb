# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def menu_items
    menu_items = ''
    
    MenuManager.get_items.each do |item|
      next unless item.respond_to?(:top_menu) || item.respond_to?(:sub_menus)
      
      menu_items += menu_item item
    end
    
    menu_items
  end
  
  def menu_item( item )
      if item.top_menu[:eval_cond] && !eval(item.top_menu[:eval_cond])
        return ''
      end
      
      label = item.top_menu[:eval_name] ? eval(item.top_menu[:eval_name]) : item.top_menu[:name]
      
      header = content_tag(item.top_menu[:top] ? :h1 : :h2, label)
      sub_menu_tag = content_tag :ul do
        sub_menus = ''
        item.sub_menus.each do |sub_menu|
          sub_menu_params = {}
          sub_menu_params = sub_menu_params.merge sub_menu
          
          eval_cond = sub_menu_params.delete :eval_cond         
          next if eval_cond && !eval(eval_cond)
          
          li_params = sub_menu == item.sub_menus.last ? {:class => 'last'} : {}
          
          if sub_menu_params[:menu_item]
            menu_item_str = menu_item(sub_menu_params[:menu_item])
            sub_menus += content_tag( :li, menu_item_str, li_params ) unless menu_item_str.empty?
          else
            eval_name = sub_menu_params.delete :eval_name 
            name = sub_menu_params.delete :name 
            id = sub_menu_params.delete :id
            additional_controllers = sub_menu_params.delete :additional_controllers
            
            label = eval_name ? eval(eval_name) : name
            
            li_params[:id => id] if id
            additional_controllers = [] unless additional_controllers
            
            sub_menus += content_tag(:li, sub_menu_item(label, sub_menu_params, additional_controllers), li_params)
          end
        end
        sub_menus
      end
      header + sub_menu_tag
  end
  
  def sub_menu_item(label, params, additional_controllers = [])
    menu_style = {}
    if @current_controller == params[:controller]
      menu_style = {:class => 'selected'}
    end
    additional_controllers.each do |controller|
      if @current_controller == controller
        menu_style = {:class => 'selected'}
        break
      end
    end
    
    link_to label, params, menu_style
  end

  def error_for(object, method = nil, options={})
      if method
        err = instance_variable_get("@#{object}").errors.on(method).to_sentence rescue instance_variable_get("@#{object}").errors.on(method)
      else
        err = @errors["#{object}"] rescue nil
      end
      if( err )
        options.merge!(:class=>'fieldWithErrors', :id=>"#{[object,method].compact.join('_')}-error", :style=>(err ? "#{options[:style]}" : "#{options[:style]};display: none;"))
        content_tag("div",err || "", options )
      else
        ''
      end
  end
  
  def error_for_subfield(object, method, options={})
      err = object.errors.on(method).to_sentence rescue object.errors.on(method)
      if( err )
        options.merge!(:class=>'fieldWithErrors', :id=>"#{[object,method].compact.join('_')}-error", :style=>(err ? "#{options[:style]}" : "#{options[:style]};display: none;"))
        content_tag("div",err || "", options )
      end
  end
  
  def error_explanation
    div_params = {:id => 'errorExplanation'}
    
    div_params[:style] = 'display:none' unless flash[:error] 
    
    content_tag :div, flash[:error], div_params
  end
  
  def notice_explanation
    div_params = {:id => 'noticeExplanation'}
    
    div_params[:style] = 'display:none' unless flash[:notice] 
    
    content_tag :div, flash[:notice], div_params
  end
  
  def element_list( elements, label )
    html = ''
    elements.each do |element|
      html += ', ' if element != elements.first
      html += element.send(label.to_s)
    end
    
    html
  end
  
  def field_class(object, field_classes, &block)
    html = ''
    return unless block_given?
    field_classes.each{ |field_class| 
      if object.class.to_s == field_class.to_s
        html = capture(&block)
        break
      end
    }
    concat(html, block.binding)
  end

  def field_enum(object, field_keys, &block)
    html = ''
    return unless block_given?
    field_keys.each{ |field_key| 
      if object.kname == field_key.to_s
        html = capture(&block)
        break
      end
    }
    concat(html, block.binding)
  end
 


  def field_enum_not(object, field_keys, &block)
    html = ''
    return unless block_given?
    match = 0
    field_keys.each{ |field_key| 
      if object.kname != field_key.to_s
        match = 1
      end
    }
    if match == 1
      html = capture(&block)
    end
    concat(html, block.binding)
  end
 
  def check_write_privilege( privilege, check_active_cfg_locked=true, &block )
    production_system_cfg = false

    if check_active_cfg_locked
      # Check if a certain config is on an active production system
      SystemInfo.find_all_by_active_configuration_id(get_current_config).each do|system|
        if system.lock_active_configuration
          production_system_cfg = true
          break
        end
      end
    end
    
    has_write_privilege = privilege >= session[:auth].write_privilege_level && !production_system_cfg
    if block_given?    
      html = ''
      if has_write_privilege
        html = capture(&block)
      end
      concat(html, block.binding)
    end
    
    has_write_privilege
  end
 
  def has_write_privilege?( check_active_cfg_locked=true, &block )
    check_write_privilege object_privilege_level, check_active_cfg_locked, &block
  end
  
  
  def has_root_level?( &block )
    html = ''
    has_root_level = session[:auth] && session[:auth].write_privilege_level == ApplicationController::ROOT_LEVEL
    return has_root_level  unless block_given?
    if has_root_level
      html = capture(&block)
    end
    concat(html, block.binding)
  end
  
  def get_current_config()
    Configuration.find( session[:current_cfg_id] ) rescue nil
  end
  
  def get_current_adapter()
    VirtualAdapter.find( session[:current_adapter_id] ) rescue nil
  end
  

  def edit_page_title(element_name)
    if has_write_privilege?
      title = 'Editing ' + element_name + ':'
    else
      title = element_name + '(read only):'
    end
  end
  
  def common_select_field(field_containter, field_name, field_label, option_map, option_value, params={}, &block )
    # option_map = []
    # option_map_in.collect { |x| option_map << [ x[0], x[1] ] unless x[0].downcase['obsolete'] }
    input_hidden = ''
    input = ''
    select_attributes = {:id => field_containter + '_' + field_name, :name => field_containter + '[' + field_name + ']'}
    select_attributes.merge! params
    if option_value && option_value.kind_of?(ActiveRecord::Base)
      option_value_id = option_value.send 'id'
    else
      option_value_id = option_value
    end
    
    if select_attributes[:disabled]
      # We need a hidden so that an disabled value is submitted 
      input_hidden = common_hidden_field(field_containter, field_name, option_value_id)
    end
    
    select = content_tag :select, options_for_select( option_map, option_value_id ), select_attributes
    if block_given?
      input = capture(&block)
    else
      input += " " + params[:desc] if params[:desc]
    end
    label = content_tag :label, field_label, :for => field_containter + '_' + field_name
    html = content_tag :p, label + select + input_hidden + "&nbsp;" + input
  end

  def common_select_tag(field_containter, field_name, option_map, option_value, params={})
    input_hidden = ''
    select_attributes = {:id => field_containter + '_' + field_name, :name => field_containter + '[' + field_name + ']'}
    select_attributes.merge! params
    if option_value && option_value.kind_of?(ActiveRecord::Base)
      option_value_id = option_value.send 'id'
    else
      option_value_id = option_value
    end
    
    if select_attributes[:disabled]
      # We need a hidden so that an disabled value is submitted 
      input_hidden = common_hidden_field(field_containter, field_name, option_value_id)
    end
    
    select = content_tag :select, options_for_select( option_map, option_value_id ), select_attributes
    html = select + input_hidden
  end
    
  def common_text_tag(field_containter, field_name, field_value, params={} )
    input_text_params = {:id => field_containter + '_' + field_name, 
      :name  => field_containter + '[' + field_name + ']',
      :type  => 'text',
      :size  => 20,
      :value => field_value }
    input_text_params.merge! params  
    
    input_text = tag :input, input_text_params
    
    html = input_text
  end  
  
  def common_file_tag(field_containter, field_name, params={} )
    input_file_params = {:id => field_containter + '_' + field_name, 
      :name  => field_containter + '[' + field_name + ']',
      :type  => 'file',
      :size  => 20 }
    input_file_params.merge! params  
    
    input_file = tag :input, input_file_params
    
    html = input_file
  end 
  
  def common_file_field(field_containter, field_name, field_label, params={})    
    label = content_tag :label, field_label, :for => field_containter + '_' + field_name
    html = content_tag :p, label + common_file_tag(field_containter, field_name, params)
  end
  
  def common_text_field_helper(field_containter, field_name, field_label, field_value, params={}, &block )
    field_id = field_containter + '_' + field_name
    label = content_tag :label, field_label, :for => field_id
    input = common_text_tag field_containter, field_name, field_value, params
      
    if block_given?
      input += capture(&block)
    else
      input += " " + params[:desc] if params[:desc]
    end
    html = content_tag :p, label + input
    
    
    if params[:first_field]
      html += update_page_tag do |page| 
        page[field_id].focus();
      end
      params.delete :first_field
    end

    html
  end
  
  def common_text_field(field_containter, field_name, field_label, field_value, params={}, &block )
    html = common_text_field_helper field_containter, field_name, field_label, field_value, params, &block

    concat(html, block.binding) if block_given?
    
    html
  end
  
  def common_text_area_tag(field_containter, field_name, field_value, params={} )
    text_params = {:id => field_containter + '_' + field_name, 
      :name  => field_containter + '[' + field_name + ']' }
    text_params.merge! params  
    
    text = content_tag :textarea, field_value, text_params
    
    html = text
  end  
  
  def common_text_area_field(field_containter, field_name, field_label, field_value, params={}, &block )
    field_id = field_containter + '_' + field_name
    label = content_tag :label, field_label, :for => field_id
    input = common_text_area_tag field_containter, field_name, field_value, params
      
    if block_given?
      input += capture(&block)
    else
      input += " " + params[:desc] if params[:desc]
    end
    html = content_tag :p, label + input
    
    
    if params[:first_field]
      html += update_page_tag do |page| 
        page[field_id].focus();
      end
      params.delete :first_field
    end

    concat(html, block.binding) if block_given?
    html
  end
  
  def common_password_tag(field_containter, field_name, field_value, params={} )
    input_password_params = {:id => field_containter + '_' + field_name, 
      :name  => field_containter + '[' + field_name + ']',
      :type  => 'password',
      :size  => 20,
      :value => field_value }
    input_password_params.merge! params  
    
    input_password = tag :input, input_password_params
    
    html = input_password
  end  
    
  def common_password_field(field_containter, field_name, field_label, field_value, params={}, &block )
    label = content_tag :label, field_label, :for => field_containter + '_' + field_name
    input = common_password_tag field_containter, field_name, field_value, params
      
    if block_given?
      input += capture(&block)
    else
      input += " " + params[:desc] if params[:desc]
    end
    html = content_tag :p, label + input
    
    concat(html, block.binding) if block_given?
    html
  end
  
  def common_checkbox_tag(field_containter, field_name, field_value, params={})
    input_checkbox_params = {:id => field_containter + '_' + field_name, 
      :name  => field_containter + '[' + field_name + ']',
      :type  => 'checkbox',
      :value => '1' }
    input_checkbox_params.merge! params
    if field_value
      input_checkbox_params[:checked] = 'checked'
    end
    input_checkbox = tag :input, input_checkbox_params
    
    # Add description
    input_checkbox += " " + params[:desc] if params[:desc]

    if input_checkbox_params[:disabled]
      # We need a hidden so that an disabled value is submitted 
      input_hidden = common_hidden_field(field_containter, field_name, field_value)
    else
      # We need a hidden so that an unchecked value is submitted 
      input_hidden = common_hidden_field(field_containter, field_name, '0')
    end

    html = input_checkbox + input_hidden
  end
  
  def common_checkbox_field(field_containter, field_name, field_label, field_value, params={})    
    label = content_tag :label, field_label, :for => field_containter + '_' + field_name
    html = content_tag :p, label + common_checkbox_tag(field_containter, field_name, field_value, params)
  end
  
  def common_hidden_field(field_containter, field_name, field_value)
    input = tag :input, {:id => field_containter + '_' + field_name, 
      :name  => field_containter + '[' + field_name + ']',
      :type  => 'hidden',
      :value => field_value }
  end

  def common_label(field_containter, field_name, field_label, &block)
    html = ''
    return unless block_given?
    capture(&block)
    label = content_tag :label, field_label, :for => field_containter + '_' + field_name
    html = content_tag :p, label + capture(&block)
    concat(html, block.binding)
  end 
  
  def selected_elements_list( element_name, parent_element, selected_elements, params )
    form_elements = params[:form_elements] || {}
    remove_element = 'remove_' + element_name
    form_row_count = form_elements.length
    action_row_count = params[:disabled] ? 0 : 1 + (params[:ordered_list] ? 4 : 0 )
    row_count = form_row_count + action_row_count
    
    content_tag :table, :id => 'list' do      
      # Create header
      header = content_tag(:tr, content_tag(:th, 'Current', :colspan => row_count))
      header += content_tag :tr do
        labels = ''
        form_elements.each do |cur_field_name, form_element|
          form_element_label = form_element[:element_label]
          labels += content_tag(:th, form_element_label || 'Value' )
        end
        labels += content_tag(:th, 'Action', :colspan => action_row_count ) unless params[:disabled]
        
        labels
      end
      
      # Create body
      body = ''
      selected_elements.each do |element|
        # Create arrow links
        arrow_link = ''
        if params[:ordered_list] && !params[:disabled]
          arrow_link += content_tag( :td, :class => :up_arrow ) do
            link_to_remote( '&uarr;', :url => { :action => 'move_higher', :id => parent_element, element_name => element.id }, :method => :post ) unless element.first?
          end
          arrow_link += content_tag( :td, :class => :top_arrow ) do
            link_to_remote( '&uArr;', :url => { :action => 'move_to_top', :id => parent_element, element_name => element.id }, :method => :post ) unless element.first?
          end
          arrow_link += content_tag( :td, :class => :down_arrow ) do
            link_to_remote( "&darr;", :url => { :action => 'move_lower', :id => parent_element, element_name => element.id }, :method => :post ) unless element.last?
          end
          arrow_link += content_tag( :td, :class => :bottom_arrow ) do
            link_to_remote( '&dArr;', :url => { :action => 'move_to_bottom', :id => parent_element, element_name => element.id }, :method => :post ) unless element.last?
          end
        end
                  
        body += content_tag :tr do
          # Create element html
          element_html = ''
          form_elements.each do |cur_field_name, form_element|
            element_value_proc = form_element[:element_value_proc]
            form_element_value = form_element[:element_value] || 'name'
            if form_element[:element_is_field]
              form_element_value = cur_field_name
            end
            
            unless element_value_proc
              element_html += content_tag( :td, element.send(form_element_value), :nowrap => true )
            else
              element_html += content_tag( :td, element_value_proc.call(element), :nowrap => true )
            end
          end           
         
          # Create remove link
          link_options_hash = {
            :url=>{ :action => remove_element, :id => parent_element, element_name => element }, 
            :loading => "Element.show('loading_indicator')",
            :complete => "Element.hide('loading_indicator')"
          }
          link_options_hash[:update] = element_name unless params[:no_update]
          remove_link = params[:disabled] ? '' : content_tag( :td, link_to_remote( 'Remove', link_options_hash ))
          
          element_html + arrow_link + remove_link
        end
      end
      footer = content_tag(:tr, content_tag(:td, '', :id => 'footer', :colspan => row_count))
      
      header + body + footer
    end
  end
  
  def available_elements_list( element_name, parent_element, params )
    form_elements = params[:form_elements] || {}
    add_element = 'add_' + element_name
    add_element_form = add_element + '_form'
    row_count = form_elements.length
    
    content_tag :table do
      # Create add link
      add_link = content_tag :td do
        link_options_hash = {
          :url => { :action => add_element, :id => parent_element, },
          :submit => add_element_form,
          :loading => "disable('" + add_element + "')",
          :complete => "enable('" + add_element + "')" 
        }
        link_options_hash[:update] = element_name unless params[:no_update]
        
        submit_to_remote( add_element, ' << ', link_options_hash ) unless params[:disabled] 
      end
      
      # Create form
      form_html = content_tag :td do
        content_tag :div, :id => add_element_form do
          content_tag :table, :id => 'list' do  
            # Create header
            header = ''
            form_elements.each do |cur_field_name, form_element|
              if form_element[:multiple_select]
                header += content_tag(:tr, content_tag(:th, 'Available', :colspan => row_count))
                break
              end
            end
            if header.empty?
              header += content_tag :tr do
                labels = ''
                form_elements.each do |cur_field_name, form_element|
                  form_element_label = form_element[:element_label]
                  labels += content_tag(:th, form_element_label || 'Value' )
                end
                
                labels
              end
            end
  
            # Create body
            body = content_tag :tr do
              columns = ''
              form_elements.each do |cur_field_name, form_element|
                available_elements = form_element[:available_elements]
                element_value_proc = form_element[:element_value_proc]
                
                columns += content_tag :td do
                  if available_elements
                    if form_element[:multiple_select]
                      common_select_tag "#{element_name.to_s}[]", cur_field_name.to_s,
                      available_elements.map {|x| 
                      if element_value_proc
                        [element_value_proc.call(x), x.id]
                      else
                        [x.name, x.id]
                      end },
                      0, :multiple => true, :class => :multiple
                    else
                      common_select_tag element_name.to_s, cur_field_name.to_s,
                        available_elements.map {|x| [x.name, x.id]}, 0
                    end
                    
                  else
                    common_text_tag element_name.to_s, cur_field_name.to_s, nil
                  end  
                end
              end
              columns
            end
            
            # Create footer
            footer = content_tag(:tr, content_tag(:td, '', :id => 'footer', :colspan => row_count))
            
            header + body + footer
          end
        end
      end
      
      content_tag(:tr, add_link + form_html)
    end
  end
  
  def common_association_table( element_name, parent_element, selected_elements, params = {} )          
    table = content_tag :table, :class => 'association' do  
      selected_elements_html = selected_elements_list( element_name, parent_element, selected_elements, params )
      available_elements_html = available_elements_list( element_name, parent_element, params )
      
      content_tag :tr do
        content_tag(:td, selected_elements_html) + content_tag(:td, available_elements_html)
      end
    end
    
    table += update_page_tag do |page| 
      page[:errorExplanation].replace error_explanation
    end
    table += update_page_tag do |page| 
      page[:noticeExplanation].replace notice_explanation
    end
  end 

  def common_fieldset_tag(params_name, params={})
    html = ''
    return unless block_given?
    if params[:collapsible]
      link = link_to_function( params_name, nil, :id => params_name + "_link" ) do |page|
                page[params_name].visual_effect_toggle :Blind
              end
    else
      link = params_name
    end
    legend = content_tag :legend, link
    style = ""
    if params[:display]
      style = "display : " + params[:display] + ";"
    end
    div = content_tag :div, :style => style, :id => params_name do
      yield
    end
    html = content_tag :fieldset, legend + div
    html
  end
  
  def common_fieldset(params_name, params={}, &block)    
    html = common_fieldset_tag(params_name, params ) { capture(&block) }
    
    concat(html, block.binding)
  end
  
  def common_copy_form( field_containter, containter_name, fields=[], params={}, &block )
    html = ''
    containter_id = field_containter.id
    link = link_to_function( 'Copy', nil, :id => "#{containter_name}_#{containter_id}_link" ) do |page|
                page[ "#{containter_name}_#{containter_id}" ].visual_effect_toggle :slide
              end
    table_lines = content_tag :tr do
      content_tag( :td, "" ) +
      content_tag( :td, "New Value" )
    end
    fields.each do |field|
      field_value = field_containter.send( "#{field}" )
      field_label = field.camelize
      label = field_label
      input = common_text_tag containter_name, field, field_value, params
      table_lines += content_tag :tr do
        content_tag( :td, label ) +
        content_tag( :td, input )
      end
    end
    url_hash = { :action => 'copy', :id => containter_id }
    url_hash[ :controller ] = params[:controller] if params[:controller]
    table_submit =  submit_to_remote( 'CopyBtn', 'Copy', 
        :url => url_hash,
        :update => "#{containter_name}s_list",
        :submit => "#{containter_name}_#{containter_id}",
  		  :loading => "Element.show('loading_indicator'); disable('validation_btn')",
  	    :complete => "Element.hide('loading_indicator'); enable('validation_btn')"
        )
    field_table = content_tag :table, table_lines
    form_table = content_tag :table do
     content_tag :tr do
        content_tag( :td, block_given? ? capture(&block) : field_table ) +
        content_tag( :td, table_submit )
     end
    end
    html = link + content_tag( :div, form_table, :id => "#{containter_name}_#{containter_id}", :style => "display: none;" )
    concat(html, block.binding) if block_given?
    html
  end
  
  def create_status_list_header
    header = content_tag :tr do
      content_tag(:th, 'Name') +
      content_tag(:th, 'Value')
    end
    
    header
  end
  
  def create_status_field( field )
    detailed_field = content_tag :td do
      tag_options = {}
      tag_options[:onmouseover] = "Tip(\"#{field.get_description}\")" unless field.get_description.empty?

      content_tag(:a, field.get_name.humanize, tag_options)
    end
    
    detailed_field += content_tag :td do
      case field.get_type
      when :list
        value = create_status_table(field)
      when :state
        value = common_select_tag( 'status_states', field.get_name, field.get_states.values.map { |enum| 
            [enum.get_string, enum.get_integer] }, field.to_i )
      else      
        value = field.to_s
      end
      
      value
    end
    
    detailed_field
  end
  
  def create_status_form( stat_list, params={} )
    if stat_list.respond_to? 'empty?'
	    if stat_list.empty?
	      return ''
	    end
	    stat = stat_list.values.first
	  else
	  	stat = stat_list
	  end
    action = params[:action]
    
    form = content_tag(:form, :class => 'cssform') do
      table = create_status_table( stat )
      table += submit_to_remote 'commit', 'Apply states', :url => { :action => action }, :loading => "disableWhileLoading(true)", :complete => "disableWhileLoading(false)", :html => {:id => 'commit'} if has_write_privilege?(false) && !action.nil?
      table += common_hidden_field( 'status_states', 'element_id', params[:element_id] ) if params[:element_id] 
      
      table
    end
      
    form
  end
  
  def create_status_table( stat )
    content_tag :table, :id => 'list' do
      body = ''
      stat.get_field_list.each do |field|
        body += content_tag :tr do
          create_status_field(field)
        end
      end
      create_status_list_header + body
    end
  end
  
  def create_timed_update_for( form_name, remote_method, update_frequency = 0, update_div_name = nil )
    form_var = form_name.tableize.gsub(/ /, '_') 
    code = "var t;\n";
    code += "var #{form_var}_frequency=#{update_frequency};\n"
    code += "var #{form_var}_kick_ready = new Object(); #{form_var}_kick_ready.value=1;"
    code += "var refresh_success = new Object(); refresh_success.value=0;"
    javascript_tag(code) + 
    content_tag( :div, :class => 'cssform', :id => "#{form_var}" )  do
      timed_form = common_fieldset_tag( form_name, :collapsible => true, :class => 'cssform') do
        query_options = common_select_field(
          'timer_states', 
          'frequency',
          'Refresh every: ', 
          { "Don't refresh"   => "0",
            "2 seconds"       => "2", 
            "5 seconds"       => "5",
            "10 seconds"      => "10",
            "15 seconds"      => "15",
            "30 seconds"      => "30"  }, 
          update_frequency.to_s ) do
              submit_to_remote 'RefreshNowButton', 'Now',
                      :html => { :id => 'RefreshNowButton' },
                      :url => { :action => remote_method },
                      :submit => "#{form_var}",
                      :update => update_div_name,
                      :loading => "disable('RefreshNowButton'); Element.show('loading_indicator'); #{form_var}_kick_ready.value=0; refresh_success.value = 0;",
                      :complete => "enable('RefreshNowButton'); Element.hide('loading_indicator'); #{form_var}_kick_ready.value=1; if( refresh_success.value ) { Element.hide('errorExplanation'); } else { Element.show('errorExplanation'); Element.update('errorExplanation', 'Refresh Failed, Server is not responding'); }",
                      200 => "refresh_success.value = 1;"
                      
          end
       
       query_options += yield if block_given?
       
       query_options       
      end

      options = { 
          :frequency => update_frequency,
          :updater_name => 'frequency_updater',
          :url => { :action => remote_method },
          :submit => "#{form_var}",
          :update => update_div_name,
          :loading => "Element.show('loading_indicator'); refresh_success.value = 0;",
          :complete => "Element.hide('loading_indicator'); #{form_var}_kick_ready.value=1; if( refresh_success.value ) { Element.hide('errorExplanation'); } else { Element.show('errorExplanation'); Element.update('errorExplanation', 'Refresh Failed, Server is not responding'); }",
          200 => "refresh_success.value = 1;" }

      code = "new Form.Element.EventObserver( 'timer_states_frequency', function(element, value) {try {\n"
      code += "#{form_var}_frequency = eval( document.getElementById( 'timer_states_frequency' ).value );\n"
      code += "stopTimer( '#{form_var}' );\n"
      code += "if( #{form_var}_frequency>0 ) { disable('RefreshNowButton'); } else { enable('RefreshNowButton'); };"
      code += "if( #{form_var}_frequency>0 ) { "
      code += "replaceTimer('#{form_var}', function() {#{remote_function( options )}}, #{form_var}_frequency, #{form_var}_kick_ready); }\n"
      code += "} catch (e) { alert('RJS error:' + e.toString()); throw e }})\n"
      timed_form += javascript_tag(code)
    end
end
end
