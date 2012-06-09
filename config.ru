require 'rubygems'
require 'rack'
require 'rack/contrib'
require 'cgi'

LIB_DIR = "#{File.dirname __FILE__}/lib/promptml"
require "#{LIB_DIR}/app_path.rb"
require "#{LIB_DIR}/change_directory.rb"
require "#{LIB_DIR}/dispatch.rb"
require "#{LIB_DIR}/list.rb"
require "#{LIB_DIR}/put_file.rb"
require "#{LIB_DIR}/run.rb"
require "#{LIB_DIR}/set_cwd.rb"
require "#{LIB_DIR}/show.rb"
require "#{LIB_DIR}/sleep.rb"
require "#{LIB_DIR}/tab_completion.rb"
require "#{LIB_DIR}/trollop_action.rb"

CLIENT_SIDE_COMMANDS = ['clear','title']
FIXED_SERVER_COMMANDS = {
  'trollop' => PrompTML::TrollopAction.new do
    opt :flag, 'A flag'
    opt :value, 'A value', :default => 10
  end,
  'sleep' => PrompTML::Sleep.new,
  'inspect_env' => Proc.new { |env,args| CGI.escapeHTML env.inspect },
  'show' => PrompTML::Show.new,
  'cd' => PrompTML::ChangeDirectory.new,
  'ls' => PrompTML::List.new,
  'run' => PrompTML::Run.new
}

PrompTML::Paths.root = '.'
dispatch = PrompTML::Dispatch.new(FIXED_SERVER_COMMANDS, PrompTML::AppsAtPath.new('/client/apps'))

builder = Rack::Builder.new do
  use Rack::CommonLogger
  use Rack::Logger

  map '/client' do
    run PrompTML::SetCwd.new(
          PrompTML::PutFile.new(
            Rack::File.new('client')
          )
        )
  end

  map '/cmd' do
    run Rack::Cookies.new(dispatch)
  end

  map '/tab' do
    run Rack::Cookies.new(
      PrompTML::TabCompletion.new(
          FIXED_SERVER_COMMANDS.keys,
          CLIENT_SIDE_COMMANDS,
          PrompTML::AppsAtPath.new('/client/apps')
        ))
  end
end

run builder


