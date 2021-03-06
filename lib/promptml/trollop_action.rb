require 'trollop'
require 'cgi'

module PrompTML
  
  # Promptml action that wraps the Trollop
  # parser and responds to --help and bad
  # arguments. Should be subclassed to provide
  # real actions.
  class TrollopAction
    def initialize &b
      @parser = Trollop::Parser.new &b
    end
  
    def call env, args
      begin
        cmd = args.shift
        opts = @parser.parse args
        return action env, cmd, opts, args
      rescue Trollop::HelpNeeded
        return pre_wrap help_message
      rescue Trollop::VersionNeeded
        return version_message
      rescue Trollop::CommandlineError => e
        raise "#{e.message}.<br />Try --help for help."
      end
    end
  
    # Override this method to create your own trollop action
    # opts - the options hash as returned by trollop
    # args - remaining arguments not parsed by trollop
    def action env, cmd, opts, args
      pre_wrap <<-EOS
  Trollop diagnostics
  #{help_message}
  #{@parser.specs.keys.collect { |k| "--#{k}=#{opts[k]}" }.sort.join("\n") }
  Remaining args: #{args.join(', ')}
  EOS
    end
  
    private
    # Format the given string by escaping any
    # sensitive html characters and wrapping
    # it in &lt;pre&gt; tags.
    def pre_wrap str
      "<pre>#{CGI.escapeHTML(str)}</pre>"
    end
  
    def help_message
      usage = StringIO.new
      @parser.educate usage
      usage.string
    end
    
    def version_message
      "<pre>#{@parser.version}</pre>"
    end
  
    def cl_error msg
      raise Trollop::CommandlineError, msg
    end
  end

end
