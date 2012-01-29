require 'uri'

class CommandDispatch
  attr_accessor :headers

  def initialize cmds = {}
    @cmds = cmds
    @headers = { "Content-Type" => "text/html" }
  end

  def []= cmd,action
    unless action.public_methods.include? :call
      raise "Action must implement call method"
    end

    @cmds[cmd] = action
  end

  def [] cmd
    @cmds[cmd]
  end

  def call env
    args = parse_args env
    cmd = args[0]

    return not_found cmd unless @cmds.key? cmd

    begin
      return command_successful @cmds[cmd].call(args)
    rescue => e
      return command_failed cmd, e
    end
  end

  private
  def not_found command
    [404,
      @headers,
      ["<span class='error'>Command '#{command}' not found.</span>"]
    ]
  end
  
  def command_failed command, error
    [500,
      @headers,
      ["<span class='error'>Command '#{command}' failed: #{error}</span>"]
    ]
  end
  
  def command_successful output
    [200,
      @headers.merge({ "Content-Length" => output.length.to_s}),
      [output]
    ]
  end

  def parse_args env
    env['QUERY_STRING'].split('+').collect { |a| URI.unescape(a) }
  end
end
