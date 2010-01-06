require "cgi"
require 'rubygems'
require 'memcached'

class FsConfiguration < ActiveRecord::Base
  has_many :fs_extensions, :order => 'position', :dependent => :delete_all

  validates_presence_of :name, :message => 'Please supply a name for the extension'

  def get_ext_hits(host)
   ha = []
   begin
     cache = Memcached.new(host)
     okeys = fs_extensions.find(:all, :conditions => ["active"], :select => "DISTINCT name").map { |ext| CGI::escape(ext.name) }
     hat = cache.get( okeys.map { |ext| "hit_" + ext }, false)
     ahat= cache.get( okeys.map { |ext| "ahit_" + ext }, false)
     ha = hat.map do |k,v| 
       answers = (ahat['a'+k] || 0).to_i
       asr = 100 * answers / (v.to_i || 1)
       if asr > 100 : asr = 100 end
       { 'name' => CGI::unescape(k[4..-1]), 
         'hits' => v, 
         'answers' => answers, 
         'asr' => asr > 0 ? asr.to_s + "%" : '',
         'status' => asr > 95 ? 'up' : asr > 85 ? 'alarm' : 'down'
       }
     end
   rescue
   end
   ha
  end
 
  def clear_ext_hits(host)
    cache = Memcached.new(host)
    fs_extensions.find(:all, :conditions => ["active"], :select => "DISTINCT name").map do |ext| 
      begin
        name = CGI::escape(ext.name)
        cache.delete("hit_" + name)
        cache.delete("ahit_" + name)
      rescue
      end
    end
  end
  
  def get_fs_status(host)
    fs = FsAPI.new(host)
    version = fs.version
    dialplan = fs.get_dialplan_version
    r = {}
    r['version'] = version['errmsg'] || version['result']
    r['version_err'] =  version['result'].blank?
    r['dialplan'] = dialplan['errmsg'] || dialplan['result']
    r['dialplan_err'] =  dialplan['result'] != get_version
    r['host'] = host
    r
  end
  
  def activate
    a = FsConfiguration.find(:first, :conditions => ['active'])
    a.active = 0
    a.commited = 0
    self.active = 1
    self.commited = 0
    a.transaction do
      a.save!
      save!
    end
    docommit
  end
  
  def docommit
    self.commited = 1
    self.version = self.version + 1
    self.save!
    fs = FsAPI.new('localhost')
    fs.provision
  end
  
  def get_version
    [name, version].join('_')
  end
#  validate_fields self
end
