require File.dirname(__FILE__) + '/trollop_action.rb'
  
module PrompTML
  
  # Action that sleeps for a number of seconds.
  # Not a particularly useful one this, but it
  # helps with testing.
  class Sleep < TrollopAction
    def initialize
      super do
        banner <<-EOS
Usage: sleep <seconds>
Waits the specified number of seconds and
then exits.
EOS
      end
    end
  
    def action env, cmd, opts, args
      cl_error 'Duration not supplied.' if args.empty?
      cl_error 'Too many arguments' if args.length > 1
      cl_error "Invalid duration '#{args[0]}'" unless /^\d+$/ =~ args[0]
  
      sleep args[0].to_i
    end
  end

end
