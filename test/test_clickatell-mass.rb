require 'helper'

class TestClickatellMass < Test::Unit::TestCase
  class TestResponseCallbackObject
    attr_accessor :responses
    
    def initialize
      @responses = []
    end
    
    def handle_response(options)
      @responses << options
    end
  end
  
  context "default" do
    setup do
      @response_callback = TestResponseCallbackObject.new
      rc_lambda = lambda{|opts| @response_callback.handle_response(opts)}
      @c = Clickatell::Sender.new
      @c.response_callbacks << rc_lambda
      Clickatell::Sender.stubs(:post).returns('a fake response')
    end
    
    should "prepare country code" do
      numbers = ["1-210-555-0000", "210-555-0001", '12105550002', '2105550003']
      assert_equal @c.send(:prepend_country_code, numbers), ["1-210-555-0000", "1210-555-0001", '12105550002', '12105550003'].join(',')
    end
    
    should "prepend country code" do
      assert_equal @c.send(:prepend_country_code, (%w{2 12})), "12,12"    
    end
  end
  
  context "parse response" do
    setup do
      @response_callback = TestResponseCallbackObject.new
      rc_lambda = lambda{|opts| @response_callback.handle_response(opts)}
      @c =  Clickatell::Sender.new
      @c.response_callbacks << rc_lambda
      Clickatell::Sender.stubs(:post).returns('a fake response')
    end
    
    context "one phonenumber" do
      should "work with success" do
        Clickatell::Sender.stubs(:post).returns("ID: 82b44ca548082ae24ccf83fa8b2a108a")
        @c.deliver('fake', ['1'])
        assert_equal @response_callback.responses.size, 1
        response = @response_callback.responses.first
        response.delete(:time)
        assert_equal response, {:recipient => '1', :claimcheck => '82b44ca548082ae24ccf83fa8b2a108a'}
      end
    
      should "work with failure" do
        Clickatell::Sender.stubs(:post).returns("ERR: 128, Number delisted\n")
        @c.deliver('fake', ['1'])
        assert_equal @response_callback.responses.size, 1
        response = @response_callback.responses.first
        response.delete(:time)
        assert_equal response, {:recipient => '1', :error => 'ERR: 128, Number delisted'}
      end
    end
  
    context "multiple phonenumbers" do
      should "work with success" do
        Clickatell::Sender.stubs(:post).returns("ID: 6471819cea4cbd45e0ea055720410878 To: 12\nID: 6b51ea281e4f64f9bddf966c04087ca5 To: 13\n")
        @c.deliver('fake', ['2', '3'])
        assert_equal @response_callback.responses.size, 2        
        first_response = @response_callback.responses.first
        first_response.delete(:time)
        assert_equal first_response, {:recipient => '2', :claimcheck => '6471819cea4cbd45e0ea055720410878'}
        
        second_response = @response_callback.responses[1]
        second_response.delete(:time)
        assert_equal second_response, {:recipient => '3', :claimcheck => '6b51ea281e4f64f9bddf966c04087ca5'}
      end
    
      should "work with failure" do
        Clickatell::Sender.stubs(:post).returns("ID: 200d56c4df859f850d4a6d2c678c3cdf To: 12\nERR: 128, Number delisted To: 13\n")
        @c.deliver('fake', ['2', '3'])
        assert_equal @response_callback.responses.size, 2        
        first_response = @response_callback.responses.first
        first_response.delete(:time)
        assert_equal first_response, {:recipient => '2', :claimcheck => '200d56c4df859f850d4a6d2c678c3cdf'}
        
        second_response = @response_callback.responses[1]
        second_response.delete(:time)
        assert_equal second_response, {:recipient => '3', :error => 'ERR: 128, Number delisted'}
      end
    
    end
  end
end
