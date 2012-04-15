require "#{File.dirname __FILE__}/paths.rb"

module PrompTML
  
  # Enumerates all of the apps at a
  # given path. Can also return a lamba proc
  # for each available app that can be
  # executed by the dispatcher.
  class AppsAtPath
    include Enumerable

    def initialize path
      @path = path
    end
    
    def each
      Paths["#{@path}/*.app"].each do |app|
        yield app_name app
      end
    end
    
    def [] app
      make_executable(app) if member? app
    end
    
   protected
    def make_executable app
      lambda { |env, args| cmd = args.shift ; Run.run [full_path(cmd), *args], env }
    end

    def full_path app
      "#{@path}/#{app}.app"
    end

    def app_name path
      File.basename(path).chomp('.app')
    end
  end
end

