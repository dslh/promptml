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
      cwd = Paths.cwd env
      output = StringIO.new
      output << "<div class='file_list'>"

      args = ['*'] if args.empty?
      args.each do |pattern|
        pattern = Paths.make_absolute pattern, cwd
        output << List.items(pattern)
      end
      
      output << "</div>"
      output.string
    end

    class << self
      # returns html for the list of files that
      # matches the given pattern
      def items pattern
        Paths[pattern].collect do |file|
          case
          when Paths.directory?(file)
            item file, 'directory', 'cd'
          when Paths.executable?(file)
            item file, 'app', 'run'
          else
            item file, 'file', 'show'
          end
        end.join
      end
  
      # returns html for a list item with a link
      # to the file.
      def item file, type, cmd
        <<-EOS
  <a href='javascript:promptml("#{cmd} #{file}")'
    class='cmd #{type}'>
      #{File.basename file}
  </a>
EOS
      end
    end

  end

end
