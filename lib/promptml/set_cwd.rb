require 'rack/request'
require 'rack/response'

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
      resp = Rack::Response.new body,status,headers
      resp.set_cookie 'CWD', '/' unless cookies.include? 'CWD'
      resp.finish
    end
  end

end
