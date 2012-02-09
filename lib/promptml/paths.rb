module PrompTML

  # Methods providing consistent path resolution and
  # navigation.
  class Paths
    class << self
      attr_reader :root
      def root= root
        @root = root.chomp('/')
      end
      
      def absolute? path
        path[0] == '/' and not /\/\.\.($|\/)/ =~ path
      end

      # Combines a relative path with an absolute path
      # to produce a new absolute path.
      def make_absolute path, base = '/'
        base = '/' if path[0] == '/'
        raise "base path (#{base}) is not absolute" unless absolute? base

        new_path = elements_of base
        elements_of(path).each do |element|
          case element
          when '.'
            next
          when '..'
            new_path.pop
          else
            new_path << element
          end
        end
        
        '/' + new_path.join('/')
      end

      def exist? path
        File.exist? real_path path
      end

      def [] pattern
        pattern = make_absolute pattern unless absolute? pattern
        Dir[@root + pattern].collect { |path| path[@root.length..-1] }
      end

      def file? path
        File.file? real_path path
      end

      def directory? path
        File.directory? real_path path
      end

      private
      def elements_of path
        path.split('/').reject { |e| e.empty? }
      end

      def real_path path
        path = make_absolute path unless absolute? path
        @root + path
      end
    end
  end

end
