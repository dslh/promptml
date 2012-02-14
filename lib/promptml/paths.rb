require 'rack/utils'

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

      # Produces a relative path from two absolute paths.
      # If the destination is not a direct subclass of
      # the source then an absolute path will be returned.
      def make_relative from, to, use_parent_dots=false
        if not (absolute? from and absolute? to)
          raise ArgumentError, "given paths must be absolute"
        end

        f = elements_of from
        t = elements_of to

        if t[0...f.size] == f
          return '.' if t.size == f.size
          t[f.size..-1].join('/')
        elsif use_parent_dots
          [f.shift,t.shift] while f[0] == t[0]
          f.collect{'..'}.join('/') + '/' + t.join('/')
        else
          '/' + t.join('/')
        end
      end

      # Produces a relative path from two absolute paths.
      # If the destination is not a direct subclass of
      # the source then a relative path will be returned.
      def make_relative! from, to
        make_relative from, to, true
      end

      # Pull the current working directory from the client's
      # cookies via the rack environment variable.
      # Rack::Cookie must be installed. The cookie referenced
      # is 'CWD'
      def cwd env
        env['rack.cookies']['CWD'] || '/'
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

      def set_cwd! header, cwd
        value = { :value => cwd, :path => '/' }
        Rack::Utils.set_cookie_header! header, "CWD", value
      end

      private
      def elements_of path
        path.split('/').reject { |e| e.empty? }
      end

      def real_path path
        raise "Paths.root is not set" unless @root
        path = make_absolute path unless absolute? path
        @root + path
      end
    end
  end

end
