require 'stringio'
require "#{File.dirname __FILE__}/paths.rb"

module PrompTML

  # The Show command shows the requested
  # document(s) in the output. So far it
  # only supports images.
  class Show
    def call env, args
      args.shift
      output = StringIO.new
      cwd = env['rack.cookies']['CWD']

      args.each do |pattern|
        pattern = Paths.make_absolute pattern, cwd
        Paths[pattern].each do |file|
          output << "<img src='/client#{file}' title='#{file}'/>"
        end
      end

      output.string
    end
  end
end
