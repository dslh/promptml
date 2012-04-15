require 'rubygems'
require 'erubis'
require "#{File.dirname __FILE__}/paths.rb"

module PrompTML

  # The 'run' command returns the contents of
  # the requested .app file verbatim, with the effect
  # that it will be 'executed' on the client.
  class Run
    def call env, args
      cmd = args.shift
      return usage(cmd) if args.empty?
      
      Run.run args, env
    end
  
    class << self
      # 'Run' an erb template app.
      def run args, env
        cwd = Paths.cwd env
        puts args.inspect
        puts cwd.inspect
        app = Paths.real_path args[0], cwd
        return error "No such file '#{args[0]}'" unless File.exist? app
        return error "Can only run .app and .erb files" unless Paths.executable? app
  
        cmd = args.shift
        erb = Erubis::Eruby.new File.read(app)
        erb.result(binding())
      end
    end
            
    
    def error message
      "<span class='error'><code>run</code> failed: #{message}</span>"
    end

    def usage cmd
      <<-EOS
<pre>
Usage: #{cmd} cmd.app [args]
Runs the given .app file. The file will be run through
an erb interpreter on the server and then appended to
the page verbatim on the client side. Meta tags or direct
embedding can be used to initiate javascript on the client
side.
</pre>
EOS
    end
  end
end

