require 'rubygems'
require 'stringio'
require 'coderay'
require "#{File.dirname __FILE__}/paths.rb"

module PrompTML

  # The Show command shows the requested
  # document(s) in the output. So far it
  # only supports images.
  class Show
    IMAGE_EXTENSIONS = ['.jpg','.jpeg','.gif','.png','.webp']
    class << self
      def image? file
        IMAGE_EXTENSIONS.include? File.extname(file).downcase
      end
    end

    def call env, args
      args.shift
      output = StringIO.new
      cwd = Paths.cwd env

      args.each do |pattern|
        pattern = Paths.make_absolute pattern, cwd
        Paths[pattern].each do |file|
          output << show_file(file)
        end
      end

      output.string
    end

    def show_file file
      <<-EOS
<div class='file'>
  <span class='file_name'>#{File.basename file}</span>
  #{Show.image?(file) ?
      "<img src='/client#{file}' title='#{file}'/>" :
      CodeRay.scan_file(Paths.real_path file).div}
</div>
EOS
    end

  end
end
