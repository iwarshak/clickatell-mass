module Clickatell
  class Query
    include HTTParty
    
    STATUS = {0 => "nil", 1 => "Message unknown", 2 => "Message queued", 3 => "Delivered to gateway", 4 => "Received by recipient", 5 => "Error with message", 6 => "User cancelled message delivery", 7 => "Error delivering message", 8 => "OK", 9 => "Routing error", 10 => "Message expired", 11 => "Message queued for later delivery", 12 => "Out of credit"}

    attr_accessor :login, :password, :appid, :logger
    
    def initialize(login = CLICKATELL_USER, password = CLICKATELL_PASSWORD, appid = CLICKATELL_APPID)
      self.login     = login
      self.password  = password
      self.appid     = appid
    end
    
    def status(message_id)
      query = default_params.merge(:apimsgid => message_id)
      response = self.class.post("http://api.clickatell.com/http/querymsg", :query => query)   
      response_code = response.scan(/Status: (.*)$/).flatten.first.to_i
      return STATUS[response_code] ? STATUS[response_code] : nil
    end
    
    
private
    def default_params
      { "api_id" => @appid, "user" => @login, "password" => @password }
    end
    
  end
end
