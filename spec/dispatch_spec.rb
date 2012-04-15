require 'promptml/dispatch'

describe PrompTML::Dispatch do
  before(:each) do
    @command = Proc.new { |env,args| args.join(',') }
    @dispatch = PrompTML::Dispatch.new({ 'test' => @command })
    @env = { 'QUERY_STRING' => 'test+one+two+three+1%202%2B3' }
  end

  it "contains a map of commands" do
    @dispatch['test'].should == @command
    @dispatch['anything else'].should be_nil
  end

  it "should pass env and an args array to the dispatched action" do
    dispatch = PrompTML::Dispatch.new({'test' => Proc.new do |env,args|
      env.should equal @env
      args.should be_an_instance_of Array
    end})
    dispatch.call @env
  end

  it "should wrap the output of the action in a rackable http response" do
    response = @dispatch.call @env
    response[0].should == 200
    response[1].should be_an_instance_of Hash
    response[2].should be == ["test,one,two,three,1 2+3"]
  end

  it "should provide the Content-Length header" do
    response = @dispatch.call @env
    response[1].should include('Content-Length' => '24')
  end

  it "should handle errors" do
    error_message = "this should be in the response"
    dispatch = PrompTML::Dispatch.new(
      {'fail' => Proc.new { |env,args| raise error_message } })
    response = dispatch.call({'QUERY_STRING' => 'fail'})
    response[0].should == 200
    response[2][0].should match error_message
  end

  it "should allow custom headers" do
    @dispatch.headers['Server']= 'promptml'
    @dispatch.headers['Refresh']= 5
    response = @dispatch.call @env
    response[1].should include('Server' => 'promptml')
    response[1].should include('Refresh' => 5)
  end

  it "should notify the user when the command is not found" do
    response = @dispatch.call({ 'QUERY_STRING' => 'bad_cmd' })
    response[0].should == 200
    response[2][0].should match 'not found'
  end

  it "returns any response given as a string" do
    dispatch = PrompTML::Dispatch.new({
      'number' => Proc.new { |env,args| 10 },
      'array' => Proc.new { |e,a| [1,2,3] }
    })
    response = dispatch.call({'QUERY_STRING' => 'number'})
    response[2][0].should == '10'
    response = dispatch.call({'QUERY_STRING' => 'array'})
    response[2][0].should == [1,2,3].to_s
  end

  it "returns Rack::Response objects without conversion" do
    dispatch = PrompTML::Dispatch.new({
      'respond' => Proc.new { |e,a| Rack::Response.new 'body' }
    })
    response = dispatch.call({'QUERY_STRING' => 'respond'})
    response.should be_a_kind_of Rack::Response
  end
end





