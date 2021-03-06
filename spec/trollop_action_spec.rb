require 'promptml/trollop_action'
require 'promptml/dispatch'

describe PrompTML::TrollopAction do
  before(:each) do
    @trollop = PrompTML::TrollopAction.new do
      banner "usage message"

      opt :flag, "An option"
      opt :value, "another", :default => 10
    end

    @commands = { 'trollop' => @trollop }
    @dispatch = PrompTML::Dispatch.new(@commands)
  end

  it "responds by default with a list of option values" do
    response = @dispatch.call({'QUERY_STRING' => 'trollop+--flag+--value+11'})
    response[0].should == 200
    response[2][0].should match /--value.*11/
  end

  it "hands back a usage message when requested" do
    response = @dispatch.call({'QUERY_STRING' => 'trollop+--help'})
    response[0].should == 200
    response[2][0].should match 'usage message'
  end

  it "hands back an error message if there are bad arguments" do
    response = @dispatch.call({'QUERY_STRING' => 'trollop+--badarg'})
    response[0].should == 200
    response[2][0].should match 'badarg'
  end

  it "can be subclassed to create new commands" do
    class TestTrollopSubclass < PrompTML::TrollopAction
      def initialize
        super do
          banner 'Testing TrollopAction subclassing'
          opt :option
        end
      end

      def action env, cmd, opts, args
        env['QUERY_STRING'].should == 'sub+--option'
        cmd.should == 'sub'
        args.empty?.should == true
        if opts[:option]
          "on"
        else
          "off"
        end
      end
    end
    @commands['sub'] = TestTrollopSubclass.new
    response = @dispatch.call({'QUERY_STRING' => 'sub+--option'})
    response[0].should == 200
    response[2][0].should match 'on'
  end

  it "provides a convenience for raising command-line errors" do
    class TestTrollopFailConvenience < PrompTML::TrollopAction
      def initialize
        super do
          banner 'hi!'
        end
      end

      def action env, cmd, opts, args
        cl_error "foobar"
      end
    end
    @commands['clfail'] = TestTrollopFailConvenience.new
    response = @dispatch.call({'QUERY_STRING' => 'clfail'})
    response[2][0].should match 'foobar'
    response[2][0].should match 'Try --help'
  end
end


