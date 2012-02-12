require 'rack/request'
require "#{File.dirname __FILE__}/paths.rb"

module PrompTML

  # Changes the current working directory.
  # The working directory is stored in the CWD
  # cookie. ChangeDirectory operates within
  # the root given by PrompTML::Paths.root.
  #
  # Requires the Rack::Cookies plugin in
  # the application stack.
  class ChangeDirectory
    def call env, args
      cookies = env['rack.cookies']
      cwd = cookies['CWD'] || '/'
      return cwd if args.length == 1
      raise "Too many arguments given." if args.length > 2

      new_wd = Paths.make_absolute args[1], cwd
      raise "#{new_wd} is not a directory" unless Paths.directory? new_wd
      cookies['CWD'] = new_wd
      ''
    end
  end

end
