require "#{File.dirname __FILE__}/paths.rb"

module PrompTML

  # Intercept put requests and save the payload
  # to the file corresponding to the request URI.
  # Other request types are passed through to a
  # wrapped Rack application
  class PutFile
    def initialize app
      @app = app
    end

    def call env
      if env['REQUEST_METHOD'] == 'PUT' then
        write_to_file env
      else
        @app.call env
      end
    end

    def write_to_file env
      file_name = env['REQUEST_PATH']
      # Strip the rack entry point prefix from the URI
      file_name = file_name[env['SCRIPT_NAME'].length..-1]
      input = env['rack.input']
      File.open Paths.real_path(file_name), 'w' do |file|
        input.each { |s| file << s }
      end
      Rack::Response.new [], 204
    end
  end
end
