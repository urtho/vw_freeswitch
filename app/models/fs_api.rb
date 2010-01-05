require 'xmlrpc/client'
require 'xmlrpc/marshal'

class FsAPI
  
  def initialize(server = 'localhost', port = 8080)
    @server, @port = server, port
    @login, @password = 'freeswitch', 'works'
    @directory = '/RPC2'
  end
  
  def fixup(value)
        value.gsub(/&lt;/, "<").
              gsub(/&gt;/, ">")
  end

  def invoke(method, *args)
    server = XMLRPC::Client.new(@server, @directory, @port, nil, nil, @login, @password, nil, 1)
    raise "missing method" if method.blank?
    begin
      result = server.call("freeswitch.api", method, args.join(' '))
    rescue => ex
      return {'result' => nil, 'errno' => ex.class, 'errmsg' => ex.message}
    end
    return {'result' => result, 'errno' => nil, 'errmsg' => nil}
  end
  
  def get_dialplan_version
    invoke('eval','${dialplan_version}')
  end
  
  def method_missing(key, *args)
    invoke(key, *args)
  end
  
end