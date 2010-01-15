class FsExtension < ActiveRecord::Base
  belongs_to :fs_configuration
  belongs_to :fs_prompt
  
  validates_presence_of :name, :message => 'Please supply a name for the extension'
  validates_numericality_of :called, :unless => Proc.new { |ext| ext.called.blank? }
  validates_numericality_of :calling, :unless => Proc.new { |ext| ext.calling.blank? }
  validates_numericality_of :remap_called, :unless => Proc.new { |ext| ext.remap_called.blank? || ext.fs_remap_called_type == 3}
    
  acts_as_list :scope => :fs_configuration
  
  @@NullPrompt = FsPrompt.new(:name => 'NONE')
  @@NullPrompt.id = 0
  @@NullPrompt.readonly!
    
  def NullPrompt
    @@NullPrompt
  end
  
  def after_save 
    fs_configuration.update_attributes!({ :commited => 0}) unless self.fs_configuration.nil? 
  end
  
  def get_calling
    get_match calling, calling_digits
  end
  
  def get_called
    get_match called, called_digits
  end
  
  def get_match(prefix, digits)
    if prefix.blank? 
      if digits.blank? or digits < 0
        _prefix = 'any'
      elsif digits == 0
        _prefix = 'empty'
      else
        _prefix = "is #{digits} digits long"
      end
    else
      if digits.blank? or digits < 0
        _prefix = "starts with #{prefix}*"
      elsif digits == 0
        _prefix = prefix
      else
        _prefix = "starts with #{prefix}" + "X" * digits 
      end     
    end
    _prefix
  end

  def get_action
    action = []
    if action_prompt && !fs_prompt.nil?
      action << (answer ? "answer and play '#{fs_prompt.name}' prompt" : "play precall '#{fs_prompt.name}' announcement")
    end
    if action_bridge 
      clir = ''
#      if clir_override then clir = ' with CLIR override' else clir = '' end
      dest = remap_called 
      if fs_remap_called_type == 2 
        if called_digits == -1
          dest << called 
          dest << "*"
        elsif called_digits == 0
          dest << called 
        else       
          dest << called 
          dest << "X" * called_digits
        end 
      elsif fs_remap_called_type == 1
        if called_digits > 0
          dest << " (+ #{called_digits} digits)"
        elsif called_digits == -1
          dest << "*"
        end
      end
      if fs_remap_called_type == 3
        action << "transfer to #{dest} service #{clir}" 
      else
        #time_limit > 0 ? action << "call [#{time_limit}s] #{dest}#{clir}" : 
        action << "call #{dest}#{clir}" 
      end 
    end
    if action.empty?
      action << 'release'
    end
    action.to_sentence
  end
  
  def get_digits_options
    a = [ ["Any number of digits", -1], ["No more digits", 0], ["1 Digit", 1] ]
    (2..16).each { |i| a << [ "#{i} Digits",i] }
    a
  end
  
  def get_remap_options
    [ 
      ['appending nothing',0],
      ['appending matched suffix',1],
      ['appending entire called number',2],
      ['to FreeSwitch service', 3]
    ]
  end
  
  def list_prompts
    prompts = [@@NullPrompt]    
    prompts + FsPrompt.find( :all )
  end
  
  def get_calling_pattern
    get_match_pattern(calling, calling_digits)
  end
  
  def get_called_pattern
    get_match_pattern(called, called_digits)
  end
  
  def get_match_pattern(number, digits)
    p = "^" + number
    if digits == -1
      p << "(\\d*)"
    elsif digits > 0
      p << "(\\d{#{digits})"
    end
    p << "[Ff]?$"
  end
  
  def get_remap_pattern
    r = remap_called
    if fs_remap_called_type == 1
      r << '$1' unless called_digits == 0
    elsif fs_remap_called_type == 2
      r << '$1'
    end
    r
  end
  
  def to_xml(options = {})
    options[:indent] ||= 2
    options[:skip_instruct] ||= true
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.extension(:name => name) do
      xml.condition(:field => 'caller_id_number', :expression => get_calling_pattern) unless calling.blank?
      xml.condition(:field => 'destination_number', :expression => get_called_pattern) do
        xml.action(:data => 'no', :application => 'privacy') if clir_override
        xml.action(:data => "+#{time_limit}", :application => 'sched_hangup') if time_limit > 0
        xml.action(:data => 'bypass_media=true', :application => 'set')
        hit = "hit_" + CGI::escape(name)
        xml.action(:data => "hits=${memcache(increment #{hit})}", :application => 'set')
        if action_prompt
          xml.action(:application => 'answer') if answer
          xml.action(:application => 'playack', :data => "/usr/local/freeswitch/sounds/pc/#{fs_prompt.filename}") 
        end
        if action_bridge
          xml.action(:application => "export", :data => "nolocal:api_on_answer=memcache increment a#{hit}")
          if fs_remap_called_type == 3
            xml.action(:data => remap_called, :application => 'transfer') 
          else  
            xml.action(:data => 'bypass_media_after_bridge=true', :application => 'set') if action_prompt
            xml.action(:data => "sofia/gateway/${sofia_profile_name}/" + get_remap_pattern, :application => 'bridge')
          end
        end
        xml.action(:application => 'hangup')
      end
    end
  end
end
  
=begin
<extension name="Map Doladowanie">
  <condition field="destination_number" expression="^1111F">
    <action application="privacy" data="no"/>
    <action application="sched_hangup" data="+59"/>
    <action application="set" data="bypass_media=true"/>
    <action application="set" data="hits=${memcache(increment hit_Doladowanie)}"/>
    <action application="bridge" data="sofia/gateway/${sofia_profile_name}/27211"/>
  </condition>
</extension>

<extension name="Announce Roaming">
  <condition field="destination_number" expression="^699438119F">
    <action application="answer"/>
    <action application="set" data="hits=${memcache(increment hit_Roaming)}"/>
    <action application="playback" data="/usr/local/freeswitch/sounds/pc/komunikat_1_bezmms"/>
    <action application="hangup"/>
  </condition>
</extension>
  
=end

