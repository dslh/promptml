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
  
    def initialize *cmd_sources
      @cmd_sources = cmd_sources
      @headers = { "Content-Type" => "text/html" }
    end
  
    def [] cmd
      @cmd_sources.each do |source|
        exec = source[cmd]
        return exec if exec
      end
      nil
    end
  
    def call env
      args = parse_args env
      cmd = args[0]
  
      exec = self[cmd]
      return not_found cmd unless exec
  
      begin
        return command_successful exec.call(env,args)
      rescue => e
        return command_failed cmd, e
      end
    end
  
    private
    def not_found command
      response "<span class='notfound'>Command '#{command}' not found.</span>"
    end
    
    def command_failed command, error
      response <<-EOS
<span class='error'>
  Command '#{command}' failed: #{error}
</span>
<ol class='stack_trace'>
  <li>
      #{error.backtrace.join("
  </li><li>
")}
  </li>
</ol>
EOS
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


