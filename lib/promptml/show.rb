require 'stringio'

module PrompTML

  # The Show command shows the requested
  # document(s) in the output. So far it
  # only supports images.
  class Show
    def call env, args
      args.shift
      output = StringIO.new
      args.each do |pattern|
        Dir["client/#{pattern}"].each do |file|
          output << "<img src='#{file[7..-1]}' title='#{file}'/>"
        end
      end

      output.string
    end
  end
end
