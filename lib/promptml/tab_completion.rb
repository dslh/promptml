require 'rack/request'
require 'rack/response'
require "#{File.dirname __FILE__}/paths.rb"

module PrompTML

  # Provides a tab completion service for both commands and files.
  # Expects GET requests of the form:
  #   /path/to/tab/completion?(cmd|file)&<root>
  #
  # TabCompletion will return four types of result:
  # * When there is only one match for the given root, it will
  #   contain only the match, with a trailing space to denote
  #   that it is an exact match.
  # * When the root given is ambiguous, it will be an HTML
  #   list of potential matches.
  # * When the given root is part of a longer root common to
  #   all matches, it will contain only the longer root with
  #   no trailing space.
  # * When there are no matches a short informational HTML
  #   message will be produced.
  class TabCompletion
    def initialize commands
      raise TypeError unless commands.respond_to? :select
      @commands = commands
    end

    def call env
      request = Rack::Request.new(env)
      unless request.query_string =~ /^(cmd|file)(&[^&]*)?$/
        return [400, {}, ['bad query string']]
      end
      type, root = request.query_string.split '&'
      cwd = Paths.cwd env
      root ||= ''

      matches = if type == 'cmd'
        matching_commands root
      else
        matching_files root, cwd
      end
      return not_found root if matches.empty?
      return single_match matches[0] if matches.size == 1

      common = common_root_of matches
      return Rack::Response.new common if root != common
      return match_list type, matches
    end

    def matching_commands root
      @commands.select { |cmd| root? cmd, root }
    end

    def matching_files root, cwd
      root = './' if root.empty?
      absolute = Paths.absolute? root
      post_slash = root[-1] == '/'
      root = Paths.make_absolute root, cwd unless absolute
      root = root.chomp('/') + '/' if post_slash
      root = root + '*' unless root[-1] == '*'
      Paths[root].collect do |match|
        directory = Paths.directory? match
        match = Paths.make_relative! cwd, match unless absolute
        match << '/' if directory
        match
      end
    end

    def common_root_of matches
      root = matches[0]
      matches.each do |match|
        root = root[0...-1] until root? match, root
      end
      root
    end

    def single_match match
      match += ' ' unless match[-1] == '/'
      Rack::Response.new match
    end

    def match_list type, matches
      Rack::Response.new <<-EOS
<ul class='#{type} matches'>
  <li>#{matches.sort.join("</li><li>")}</li>
</ul>
EOS
    end

    def not_found root
      Rack::Response.new <<-EOS
<span class='error'>
  Nothing matches <code>#{root}</code>
</span>
EOS
    end

    def root? str, root
      str.index(root) == 0
    end
  end
end
