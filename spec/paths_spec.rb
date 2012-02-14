require 'promptml/paths'

module PrompTML
  describe Paths do
    before(:each) do
      Paths.root = 'spec'
    end
  
    it "can tell you if a path is absolute or not" do
      Paths.absolute?('/absolute/path').should be_true
      Paths.absolute?('not/absolute').should be_false
      Paths.absolute?('/has/./relative/../elements').should be_false
      Paths.absolute?('/').should be_true
      Paths.absolute?('../relative').should be_false
      Paths.absolute?('.').should be_false
    end

    it "can produce an absolute path from an absolute path plus a relative one" do
      Paths.make_absolute('relative/path','/absolute/path').should == '/absolute/path/relative/path'
      Paths.make_absolute('/absolute/path','/another/absolute').should == '/absolute/path'
      # hey look it's yoda
      Paths.make_absolute('trailing/slashes/make/','/no/difference/').should == '/no/difference/trailing/slashes/make'
      Paths.make_absolute('.','/a/b/c').should == '/a/b/c'
      Paths.make_absolute('..','/a/b/c/').should == '/a/b'
      Paths.make_absolute('../d','/a/b/c').should == '/a/b/d'
      Paths.make_absolute('../d/./e/../f/','/a/b/c').should == '/a/b/d/f'
      Paths.make_absolute('../../../..','/a').should == '/'
      Paths.make_absolute('are//ignored','/double//slashes').should == '/double/slashes/are/ignored'
    end

    it "can derive a relative path from two absolute ones" do
      Paths.make_relative('/a/b','/a/b/c').should == 'c'
      Paths.make_relative('/a/','/a/b/c/').should == 'b/c'
      Paths.make_relative('/a/b/c','/a/b/c/').should == '.'
      Paths.make_relative('/','/a/b/c').should == 'a/b/c'
      Paths.make_relative('/d/','/a/b/c/').should == '/a/b/c'
      Paths.make_relative('/a/b/d','/a/b/c').should == '/a/b/c'
      Paths.make_relative!('/a/b/d','/a/b/c/').should == '../c'
    end

    it "can tell you if a file exists or not" do
      Paths.exist?('paths_spec.rb').should be_true
      Paths.exist?('/paths_spec.rb').should be_true
      Paths.exist?('/doesnt.exist').should be_false
      Paths.exist?('spec/paths_spec.rb').should be_false
      Paths.root = '.'
      Paths.exist?('spec/paths_spec.rb').should be_true
      Paths.exist?('spec/').should be_true
      Paths.exist?('spec').should be_true
      Paths.exist?('/spec/../spec').should be_true
    end

    it "can do pattern matching" do
      Paths['/doesnt.exist'].should be_empty
      Paths['/paths_spec.rb'].should == ['/paths_spec.rb']

      # Make sure we're trapped in the fake root
      Paths['/../paths_spec.rb'].should == ['/paths_spec.rb']
      Paths['../paths_spec.rb'].should == ['/paths_spec.rb']

      # Wildcards
      Paths['*.rb'].should include '/paths_spec.rb'
      Paths.root = '.'
      Paths['*'].should include '/spec'
      Paths['../*'].should include '/spec'
    end

    it "can tell the difference between files and directories" do
      Paths.file?('paths_spec.rb').should be_true
      Paths.file?('/paths_spec.rb').should be_true
      Paths.file?('doesnt_exist').should be_false

      Paths.root = '.'
      Paths.directory?('spec').should be_true
      Paths.directory?('spec/paths_spec.rb').should be_false
      Paths.file?('spec').should be_false
    end
    
    it "should be able to set the cwd as a cookie" do
      test_path = "test/path"
      expected_cookie = "CWD=test%2Fpath"
      header = {}
      Paths.set_cwd! header, test_path
      header['Set-Cookie'].should match expected_cookie

      another_cookie = "COOKIE=cookie"
      header = {"Set-Cookie" => another_cookie}
      Paths.set_cwd! header, test_path
      header['Set-Cookie'].should match expected_cookie
      header['Set-Cookie'].should match another_cookie
    end
  end
end
