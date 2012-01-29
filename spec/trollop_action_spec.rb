# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'trollop_action'
require 'command_dispatch'

describe TrollopAction do
  before(:each) do
    @dispatch = CommandDispatch.new
    @trollop = TrollopAction.new do
      banner "usage message"

      opt :flag, "An option"
      opt :value, "another", :default => 10
    end

    @dispatch['trollop'] = @trollop
  end

  it "responds by default with a list of option values" do
    response = @dispatch.call({'QUERY_STRING' => 'trollop+--flag+--value+11'})
    response[0].should == 200
    response[2].should match /--value.*11/
  end

  it "hands back a usage message when requested" do
    response = @dispatch.call({'QUERY_STRING' => 'trollop+--help'})
    response[0].should == 200
    response[2].should match 'usage message'
  end

  it "hands back an error message if there are bad arguments" do
    response = @dispatch.call({'QUERY_STRING' => 'trollop+--badarg'})
    response[0].should >= 500
    response[2].should match 'badarg'
  end

  it "can be subclassed to create new commands" do
    class TestTrollopSubclass < TrollopAction
      def initialize
        super do
          banner 'Testing TrollopAction subclassing'
          opt :option
        end
      end

      def action opts, args
        if opts[:option]
          "on"
        else
          "off"
        end
      end
    end
    @dispatch['sub'] = TestTrollopSubclass.new
    response = @dispatch.call({'QUERY_STRING' => 'sub+--option'})
    response[0].should == 200
    response[2].should match 'on'
  end
end

