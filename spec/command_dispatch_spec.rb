# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'command_dispatch'

describe CommandDispatch do
  before(:each) do
    @command_dispatch = CommandDispatch.new
    @command = Proc.new { |args| args.join(',') }
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

  it "should pass an args array to the dispatched action" do
    @command_dispatch['test'] = Proc.new do |args|
      args.should be_an_instance_of Array
    end
  end

  it "should wrap the output of the action in a rackable http response" do
    @command_dispatch['test']= @command
    response = @command_dispatch.call @env
    response[0].should be >= 200
    response[0].should be < 300
    response[1].should be_an_instance_of Hash
    response[2].should be == "test,one,two,three,1 2+3"
  end

  it "should provide the Content-Length header" do
    @command_dispatch['test']= @command
    response = @command_dispatch.call @env
    response[1].should include('Content-Length' => '24')
  end

  it "should allow custom headers" do
    @command_dispatch['test']= @command
    @command_dispatch.headers['Server']= 'promptml'
    @command_dispatch.headers['Refresh']= 5
    response = @command_dispatch.call @env
    response[1].should include('Server' => 'promptml')
    response[1].should include('Refresh' => 5)
  end

  it "should 404 when the command is not found" do
    @command_dispatch.call(@env)[0].should == 404
  end
end

