require 'clickatell'

describe Clickatell do
  
  it "should only connect once if there are less than 50 users" do
    http_post = stub("post", :read_timeout= => true, :body => "foo")
    Net::HTTP.should_receive(:start).exactly(1).times.and_return(http_post)
    
    small_user_list = []
    1.upto(5) {|c| small_user_list << c}
    
    client = Clickatell.new
    client.stub!(:generate_query)
    client.stub!(:parse_response).and_return([])
    client.send("foo", small_user_list)
  end
  
  it "should connect once if there exactly 50 users" do
    http_post = stub("post", :read_timeout= => true, :body => "foo")
    Net::HTTP.should_receive(:start).exactly(1).times.and_return(http_post)
    
    small_user_list = []
    1.upto(50) {|c| small_user_list << c}
    small_user_list.size.should eql(50)
    
    client = Clickatell.new
    client.stub!(:generate_query)
    client.stub!(:parse_response).and_return([])
    client.send("foo", small_user_list)
  end
  
  it "should break up user list into groups of 50" do
    http_post = stub("post", :read_timeout= => true, :body => "foo")
    Net::HTTP.should_receive(:start).exactly(2).times.and_return(http_post)
    
    big_user_list = []
    1.upto(51) {|c| big_user_list << c}
    
    client = Clickatell.new
    client.stub!(:generate_query)
    client.stub!(:parse_response).and_return([])
    client.send("foo", big_user_list)
  end
  
  it "should return a successful status" do
    Net::HTTP.should_receive(:start).and_return(stub(:resp_stub, :body =>"ID: fa4188eec8889a17d841b321bdc32d2b Status: 004"))
    client = Clickatell.new
    client.get_status("foo").should eql("Received by recipient")
  end
  
  it "should report your accounts credit balance" do
    Net::HTTP.should_receive(:start).and_return(stub(:resp_stub, :body =>"Credit: 2192.4"))
    client = Clickatell.new
    client.credit_balance.should eql("2192.4".to_i)
  end
  
  it "should get the coverage report for a phone number" do
    Net::HTTP.should_receive(:start).and_return(stub(:resp_stub, :body =>  "OK: This prefix is currently supported. Messages sent to this prefix will be routed. Charge: 1\n"))
    client = Clickatell.new
    client.coverage_query("12104445555").should eql("OK: This prefix is currently supported. Messages sent to this prefix will be routed. Charge: 1\n")
  end
    
    
   
    
end