# Promptml action that wraps the Trollop
# parser and responds to --help and bad
# arguments. Should be subclassed to provide
# real actions.

require 'trollop'
require 'cgi'

class TrollopAction
  def initialize &b
    @parser = Trollop::Parser.new &b
  end

  def call args
    begin
      opts = @parser.parse args
      return action opts, args
    rescue Trollop::HelpNeeded
      return pre_wrap help_message
    rescue Trollop::VersionNeeded
      return version_message
    rescue Trollop::CommandlineError => e
      raise "Error: #{e.message}.<br />Try --help for help."
    end
  end

  # Override this method to create your own trollop action
  # opts - the options hash as returned by trollop
  # args - remaining arguments not parsed by trollop
  def action opts, args
    pre_wrap <<-EOS
Trollop diagnostics
#{help_message}
#{@parser.specs.keys.sort.collect { |k| "--#{k}=#{opts[k]}" }.join("\n") }
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
    raise CommandlineError, msg
  end
end
