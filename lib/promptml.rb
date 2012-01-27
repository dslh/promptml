require 'rubygems'
require 'rack'
require 'uri'

def parse_args env
  env['QUERY_STRING'].split('+').collect { |a| URI.unescape(a) }
end

def bullet_point_args env
  <<-EOS
<ul>
  <li>
    #{parse_args(env).join("
  </li>
  <li>
    ")}
  </li>
</ul>
EOS
end

class HappyWrapper
  def initialize method
    @method = method
  end

  def call env
    [
      200,
      {"Content-Type" => "text/html"},
      @method.call(env)
    ]
  end
end

Rack::Handler::Thin.run HappyWrapper.new(method(:bullet_point_args))