require 'stringio'
require "#{File.dirname __FILE__}/paths.rb"

module PrompTML

  # Lists files and directories that match
  # the given pattern(s). If no arguments are
  # given the contents of the current working
  # directory are listed.
  class List
    def call env, args
      args.shift
      cwd = env['rack.cookies']['CWD']
      output = StringIO.new
      output << "<div class='file_list'>"

      args = ['*'] if args.empty?
      args.each do |pattern|
        pattern = Paths.make_absolute pattern, cwd
        Paths[pattern].each do |file|
          type = Paths.directory?(file) ? 'directory' : 'file'
          output << item(file, type)
        end
      end
      
      output << "</div>"
      output.string
    end

    # returns html for a list item with a link
    # to the file.
    def item file, type
      <<-EOS
  <a href='javascript:promptml("#{
    type == 'file' ? 'show' : 'cd'
  } #{file}")'
    class='cmd #{type}'>
      #{File.basename file}
  </a>
EOS
    end

  end

end
