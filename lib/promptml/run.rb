require "#{File.dirname __FILE__}/paths.rb"

module PrompTML

  # The 'run' command returns the contents of
  # the requested .app file verbatim, with the effect
  # that it will be 'executed' on the client.
  class Run
    def call env, args
      cmd = args.shift
      return usage(cmd) if args.length != 1

      cwd = Paths.cwd env
      app = Paths.real_path args[0], cwd
      return error "No such file '#{args[1]}'" unless File.exist? app
      return error "Can only run files with the .app extension" unless File.extname(app) == ".app"

      File.read app
    end
    
    def error message
      "<span class='error'><code>run</code> failed: #{message}</span>"
    end
  end
end
