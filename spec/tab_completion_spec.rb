require 'promptml/tab_completion'
require 'promptml/paths'
require 'rack/mock'
require 'rack/contrib/cookies'

module PrompTML

  describe TabCompletion do
    before(:all) do
      Paths.root = 'spec/test_fs'
    end

    before(:each) do
      @app = TabCompletion.new ['foo','bar','baz']
      @app = Rack::Cookies.new(@app)
      @request = Rack::MockRequest.new(@app)
      @opts = { 'HTTP_COOKIE' => 'CWD=%2Ffolder' }
    end

    it "should be constructed with a list of commands" do
      TabCompletion.new ['a','b','c']
      expect { TabCompletion.new }.to raise_error
    end

    it "should return the command matching the given root" do
      response = @request.get('/tab?cmd&f', @opts)
      response.status.should == 200

      # A trailing space denotes an exact match
      response.body.should == 'foo '
    end

    it "should list all matches for ambiguous roots" do
      response = @request.get('/tab?cmd&ba', @opts)
      response.status.should == 200

      # A disambiguation list may include arbitrary html
      # but must include all matches.
      response.body.should match 'bar'
      response.body.should match 'baz'
    end

    it "should produce the longest common root for ambiguities" do
      response = @request.get('/tab?cmd&b', @opts)

      # No trailing space indicates an ambiguous root
      response.body.should == 'ba'
    end

    it "should give a full command listing when no root is given" do
      response = @request.get('/tab?cmd', @opts)
      response.body.should match 'foo'
      response.body.should match 'bar'
      response.body.should match 'baz'
    end

    it "should match absolute paths" do
      response = @request.get('/tab?file&/file_1.', @opts)
      response.body.should == '/file_1.txt '

      response = @request.get('/tab?file&/file_', @opts)
      response.body.should match 'file_1.txt'
      response.body.should match 'file_2.txt'

      response = @request.get('/tab?file&/folder/file_a.t', @opts)
      response.body.should == '/folder/file_a.txt '
    end

    it "should match relative paths" do
      response = @request.get('/tab?file&file_a.', @opts)
      response.body.should == 'file_a.txt '

      response = @request.get('/tab?file&file_', @opts)
      response.body.should match 'file_a.txt'
      response.body.should match 'file_b.txt'

      response = @request.get('/tab?file&fi', @opts)
      response.body.should == 'file_'
    end

    it "should match directories with a trailing slash" do
      response = @request.get('/tab?file&s', @opts)
      response.body.should == 'subfolder/'

      response = @request.get('/tab?file&/f', @opts)
      response.body.should match '/folder/'
      response.body.should match '/file_1.txt'
    end

    it "should list whole directories" do
      response = @request.get('/tab?file', @opts)
      response.body.should match 'subfolder/'
      response.body.should match 'file_a.txt'
      response.body.should match 'file_b.txt'

      response = @request.get('/tab?file&/', @opts)
      response.body.should == '/f'

      response = @request.get('/tab?file&subfolder/', @opts)
      response.body.should == 'subfolder/one_file.txt '
    end

    it "should supply a message if no result is found" do
      expected_text = "Nothing matches"
      response = @request.get('/tab?cmd&far', @opts)
      response.body.should match expected_text

      response = @request.get('/tab?file&doesnt/exist', @opts)
      response.body.should match expected_text

      response = @request.get('/tab?file&/doesnt/exist', @opts)
      response.body.should match expected_text
    end
  end

end
