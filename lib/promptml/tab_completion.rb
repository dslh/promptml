require 'rack/request'
require 'rack/response'
require "#{File.dirname __FILE__}/paths.rb"
require 'json'

module PrompTML

  # Provides a tab completion service for both commands and files.
  # Expects GET requests of the form:
  #   /path/to/tab/completion?(cmd|file)&<root>
  #
  # TabCompletion will return four types of result, which should
  # be passed through eval() on the client:
  # * When there is only one match for the given root, it will
  #   contain a string that is the match, with a trailing space
  #   to denote that it is an exact match.
  # * When the given root is part of a longer root common to
  #   all matches, it will contain a string that is the longer
  #   root with no trailing space.
  # * When the root given is ambiguous, it will be an array of
  #   the potential matches.
  # * When there are no matches it will be null.
  class TabCompletion
    
    def initialize *command_sources
      @command_sources = command_sources
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
      return not_found if matches.empty?
      return single_match matches[0] if matches.size == 1

      common = common_root_of matches
      return Rack::Response.new common.to_json if root != common
      return match_list matches
    end

    def matching_commands root
      @command_sources.collect do |source|
        source.select { |cmd| root? cmd, root }
      end.flatten
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
      Rack::Response.new match.to_json
    end

    def match_list matches
      Rack::Response.new matches.to_json
    end

    def not_found
      Rack::Response.new nil.to_json
    end

    def root? str, root
      str.index(root) == 0
    end
  end
end
