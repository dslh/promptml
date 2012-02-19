require 'uri'
require 'rack/response'

module PrompTML

  # The Dispatcher is the entry point from rack into PrompTML.
  # It contains a hash of named actions and parses the url
  # query string as command line arguments. When the command
  # matches the name of one of the actions the command is executed.
  #
  # Commands are passed two arguments:
  #  env  - the standard rack environment variable
  #  args - an array of command line arguments, as parsed
  #         from the query string. The first argument
  #         is the command itself.
  class Dispatch
    attr_accessor :headers
  
    def initialize cmds = {}
      @cmds = cmds
      @headers = { "Content-Type" => "text/html" }
    end
  
    def []= cmd,action
      unless action.respond_to? :call
        raise "Action must implement call method"
      end
  
      @cmds[cmd] = action
    end
  
    def [] cmd
      @cmds[cmd]
    end

    def commands
      @cmds.keys
    end
  
    def call env
      args = parse_args env
      cmd = args[0]
  
      return not_found cmd unless @cmds.key? cmd
  
      begin
        return command_successful @cmds[cmd].call(env,args)
      rescue => e
        return command_failed cmd, e
      end
    end
  
    private
    def not_found command
      response "<span class='notfound'>Command '#{command}' not found.</span>"
    end
    
    def command_failed command, error
      response "<span class='error'>Command '#{command}' failed: #{error}</span>"
    end
    
    def command_successful output
      if Rack::Response === output then
        output
      else
        response output
      end
    end
  
    # Wraps a string in a rack-conformant response
    def response output
      output = output.to_s
      [200,
        @headers.merge({ "Content-Length" => output.length.to_s }),
        [output]
      ]
    end
  
    def parse_args env
      env['QUERY_STRING'].split('+').collect { |a| URI.unescape(a) }
    end
  end

end
