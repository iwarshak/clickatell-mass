require 'rubygems'
require 'active_support'
require 'net/http'
require 'uri'
require 'logger'

class Clickatell
  STATUS = {0 => "nil", 1 => "Message unknown", 2 => "Message queued", 3 => "Delivered to gateway", 4 => "Received by recipient", 5 => "Error with message", 6 => "User cancelled message delivery", 7 => "Error delivering message", 8 => "OK", 9 => "Routing error", 10 => "Message expired", 11 => "Message queued for later delivery", 12 => "Out of credit"}
end

class Clickatell
  attr_accessor :logfile, :log
  attr_accessor :username, :password, :app_id
  
  def initialize(&block)
    yield self if block_given?
    init_log
    self
  end
  
  def init_log
    @log = Logger.new(logfile || 'clickatell.log')
  end

  def send(message, to)
    claimchecks = []
    time = Time.now
    log.info("Sending message to #{to.to_a.size} users.")
    to.to_a.in_groups_of(50, false) do |arr| 
      
      log.info("Sending broken up message to #{arr.size} users")
      params = {"api_id" => app_id, "user" => username, "password" => password}
      params["text"] = strip_unicode_characters(message)[0..159]
      params["to"]= arr.map{|c| "1#{c}"}.join(',')

      url = URI.parse("http://api.clickatell.com/http/sendmsg")
    
      begin
        res = Net::HTTP.start(url.host, url.port) do |http|
                http.read_timeout = 120
                http.post(url.path, generate_query(params))
              end
        log.info("Sending #{message} to #{arr.join(',')}")
        response = parse_response(res.body, arr)
        log.debug("Response: #{response.join(',')}")
        
        claimchecks += response.map do |r|
          {:phonenumber => r[1], :claimcheck => r[0],:message => message,:time => time}
        end
        
      rescue
        log.error("Caught an error. #{$!}")
        raise
      end
    end
    return claimchecks
    
  end
  
  def get_status(message_id)
    params = {"api_id" => app_id, "user" => username, "password" => password, "apimsgid" => message_id}
    url = URI.parse("http://api.clickatell.com/http/querymsg")
    res = Net::HTTP.start(url.host, url.port) do |http|
            http.get(url.path + "?" + generate_query(params))
          end
    t = res.body.scan(/Status: (.*)/).flatten.first.to_i
    t == 0 ? res.body : STATUS[t]
  end
  
  def credit_balance
    url = URI.parse("http://api.clickatell.com/http/getbalance")
    res = Net::HTTP.start(url.host, url.port) do |http|
            http.get(url.path + "?" + generate_query({"session_id" => generate_session}))
          end
    t = res.body.scan(/Credit: (.*)/).flatten.first.to_i
  end
  
  def coverage_query(number)
    params = {"api_id" => app_id, "user" => username, "password" => password, "msisdn" => number}
    url = URI.parse("http://api.clickatell.com/utils/routeCoverage.php")
    res = Net::HTTP.start(url.host, url.port) do |http|
            http.get(url.path + "?" + generate_query(params))
          end
    res.body
  end
    
  
  def generate_session
    url = URI.parse("http://api.clickatell.com/http/auth")
    params = {"api_id" => app_id, "user" => username, "password" => password}
    
    res = Net::HTTP.start(url.host, url.port) do |http|
            http.get(url.path + "?" + generate_query(params))
          end
    t = res.body.scan(/OK: (.*)/).flatten.first
  end
    

  def generate_query(params)
    param_string= "" 
    params.each do |k,v|
      param_string += "#{k}=#{URI.encode(v)}&"
    end
    param_string
  end


  def parse_response(resp, recipients = nil)
    raise "Error in the response: #{resp}" if resp.match(/ERR/)
    begin
      if resp.match(/To/)
        resp.scan(/ID: (.*) To: 1(.*)/)
      else
        [] << (resp.scan(/ID: (.*)/).first << recipients.first)
      end
    rescue
      log.error("Caught an exception in parse_response. #{$!} Full response: #{resp}")
      raise
    end
  end
  
  private 

  
  def strip_unicode_characters(message)
    return message.unpack("c*").reject {|c| c <0 || c>255}.pack("c*")
  end
end