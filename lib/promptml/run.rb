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

      cwd = Paths.cwd env
      app = Paths.real_path args[0], cwd
      return error "No such file '#{args[1]}'" unless File.exist? app
      return error "Can only run files with the .app extension" unless File.extname(app) == ".app"

      cmd = args.shift
      erb = Erubis::Eruby.new File.read(app)
      erb.result(binding())
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
