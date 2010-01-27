# ssh -gNR 8001:localhost:3000 campuswire
module Clickatell
  NO_STATUS = "0"
  INTERMEDIATE_STATUS = "1"
  FINAL_STATUS = "2"
  FINAL_AND_INTERMEDIATE_STATUS = "3"
  
  class Sender
    include HTTParty
  
    SEND_ENDPOINT = "http://api.clickatell.com/http/sendmsg"
    RETURN_CODES = {
      0 => "nil", 1 => "Message unknown", 2 => "Message queued", 3 => "Delivered to gateway", 4 => "Received by recipient", 5 => "Error with message", 6 => "User cancelled message delivery", 7 => "Error delivering message", 8 => "OK", 9 => "Routing error", 10 => "Message expired", 11 => "Message queued for later delivery", 12 => "Out of credit"
    }
  
    attr_accessor :login, :password, :appid, :logger, :mailer_callback, :response_callbacks, :client_message_id
  
    def initialize(login = CLICKATELL_USER, password = CLICKATELL_PASSWORD, appid = CLICKATELL_APPID)
      self.login     = login
      self.password  = password
      self.appid     = appid
      self.response_callbacks = []
    end
  
    def deliver(message, recipients = [], callback = "0")
      text = prepare_text(message)
      send_time = Time.now
      recipients.to_a.in_groups_of(200) do |recipient_group| # 300 is the max, but want to be safe
        begin
          recipient_group.compact!
          query = default_params.merge(:text => text, :to => prepend_country_code(recipient_group), :callback => callback.to_s)
          query['cliMsgId'] = client_message_id
          logger.info("Sent #{message} to #{recipient_group.join(',')}") if logger
          response = self.class.post(SEND_ENDPOINT, {:query => query, :debug_output => $stderr})
          logger.info("Response: #{response}") if logger
          handle_deliver_response_callback(recipient_group, response, message, send_time)
        rescue Exception => e
          logger.error("Caught an error in deliver. #{e}") if logger
          mailer_callback.call("Error in Clickatell", "#{e}\n #{$!.backtrace}") if @mailer_callback
        end
      end
    end
  
  private

    def handle_deliver_response_callback(recipients, response, message, time)
      response_callbacks.each do |response_callback|
        begin
          parsed_response = parse_response(response, recipients)
          time = Time.now
          parsed_response.each do |r|
            response_callback.call(r)
          end
        rescue Exception => e
          logger.fatal("Error parsing responses. \n#{response}\n#{e.backtrace}") if logger
          mailer_callback.call("Error parsing responses.", "#{e.backtrace}") if @mailer_callback
        end
      end
    end
  
    def default_params
      { "api_id" => @appid, "user" => @login, "password" => @password }
    end
  
    def prepare_text(message)
      strip_unicode(message)[0..159]
    end
  
    def strip_unicode(message)
      message.unpack("c*").reject {|c| c <0 || c>255}.pack("c*")
    end
  
    def prepend_country_code(numbers)
      numbers.collect do |number|
        if number =~ /^1/
          number
        else
          "1#{number}"
        end
      end.compact.join(',')
    end
  
    def parse_response(resp, recipients = [])
      parsed_responses = []
      responses = resp.split(/\n/)
      # responses.size should == recipients.size. 
      responses.each_with_index do |response,i|      
        if response.match(/ERR/)
          # "ID: 200d56c4df859f850d4a6d2c678c3cdf To: 12105555555\nERR: 128, Number delisted To: 12\n"
          if response.match(/To/)  
            t_err, t_to = response.scan(/(.*) To: 1(.*)/).flatten
            parsed_responses << { :recipient => t_to, :error => t_err }
          else
            parsed_responses << { :recipient => recipients.first, :error => response }
          end
        else
          if response.match(/To/)
            # "ID: 6471819cea4cbd45e0ea055720410878 To: 12105555555\nID: 6b51ea281e4f64f9bddf966c04087ca5 To: 12105555555\n"
            t_id, t_to = response.scan(/ID: (.*) To: 1(.*)/).flatten
            parsed_responses << { :recipient => t_to, :claimcheck => t_id }
          else
            # "ID: 82b44ca548082ae24ccf83fa8b2a108a"
            parsed_responses << { :recipient => recipients.first, :claimcheck => response.scan(/ID: (.*)/).flatten.first }
          end
        end
      end
      return parsed_responses
    end
  end
end