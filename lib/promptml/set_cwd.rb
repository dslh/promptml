require 'rack/request'
require 'rack/response'
require "#{File.dirname __FILE__}/paths.rb"

module PrompTML

  # SetCwd ensures that the CWD cookie is always set.
  # If not, it defaults to the root directory '/'
  class SetCwd
    def initialize app
      @app = app
    end
  
    def call env
      cookies = Rack::Request.new(env).cookies
      status,headers,body = @app.call env
      Paths.set_cwd! headers, '/' unless cookies.include? 'CWD'
      [status, headers, body]
    end
  end

end
