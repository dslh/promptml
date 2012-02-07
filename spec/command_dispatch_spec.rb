# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'command_dispatch'

describe CommandDispatch do
  before(:each) do
    @command_dispatch = CommandDispatch.new
    @command = Proc.new { |env,args| args.join(',') }
    @env = { 'QUERY_STRING' => 'test+one+two+three+1%202%2B3' }
  end

  it "contains a map of commands" do
    @command_dispatch['test'] = @command
    @command_dispatch['test'].should == @command
    @command_dispatch['anything else'].should be_nil
  end

  it "rejects actions that cannot be invoked" do
    action = "String has no call() method"
    expect { @command_dispatch['test'] = action }.to raise_error
  end

  it "should pass env and an args array to the dispatched action" do
    @command_dispatch['test'] = Proc.new do |env,args|
      env.should equal @env
      args.should be_an_instance_of Array
    end
    @command_dispatch.call @env
  end

  it "should wrap the output of the action in a rackable http response" do
    @command_dispatch['test']= @command
    response = @command_dispatch.call @env
    response[0].should == 200
    response[1].should be_an_instance_of Hash
    response[2].should be == ["test,one,two,three,1 2+3"]
  end

  it "should provide the Content-Length header" do
    @command_dispatch['test']= @command
    response = @command_dispatch.call @env
    response[1].should include('Content-Length' => '24')
  end

  it "should handle errors" do
    error_message = "this should be in the response"
    @command_dispatch['fail']= Proc.new { |env,args| raise error_message }
    response = @command_dispatch.call({'QUERY_STRING' => 'fail'})
    response[0].should == 200
    response[2][0].should match error_message
  end

  it "should allow custom headers" do
    @command_dispatch['test']= @command
    @command_dispatch.headers['Server']= 'promptml'
    @command_dispatch.headers['Refresh']= 5
    response = @command_dispatch.call @env
    response[1].should include('Server' => 'promptml')
    response[1].should include('Refresh' => 5)
  end

  it "should notify the user when the command is not found" do
    response = @command_dispatch.call(@env)
    response[0].should == 200
    response[2][0].should match 'not found'
  end

  it "returns any response given as a string" do
    @command_dispatch['number'] = Proc.new { |env,args| 10 }
    @command_dispatch['array'] = Proc.new { |e,a| [1,2,3] }
    response = @command_dispatch.call({'QUERY_STRING' => 'number'})
    response[2][0].should == '10'
    response = @command_dispatch.call({'QUERY_STRING' => 'array'})
    response[2][0].should == '[1, 2, 3]'
  end
end

