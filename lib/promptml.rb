require 'rubygems'
require 'rack'
require 'rack/contrib'
require 'cgi'

LIB_DIR = "#{File.dirname __FILE__}/promptml"
require "#{LIB_DIR}/change_directory.rb"
require "#{LIB_DIR}/dispatch.rb"
require "#{LIB_DIR}/set_cwd.rb"
require "#{LIB_DIR}/show.rb"
require "#{LIB_DIR}/sleep.rb"
require "#{LIB_DIR}/trollop_action.rb"

PrompTML::Paths.root = 'client'
dispatch = PrompTML::Dispatch.new({
  'trollop' => PrompTML::TrollopAction.new do
    opt :flag, 'A flag'
    opt :value, 'A value', :default => 10
  end,
  'sleep' => PrompTML::Sleep.new,
  'inspect_env' => Proc.new { |env,args| CGI.escapeHTML env.inspect },
  'show' => PrompTML::Show.new,
  'cd' => PrompTML::ChangeDirectory.new
  })

builder = Rack::Builder.new do
  use Rack::CommonLogger

  map '/client' do
    run PrompTML::SetCwd.new(Rack::File.new('client'))
  end

  map '/cmd' do
    run Rack::Cookies.new(dispatch)
  end
end

Rack::Handler::WEBrick.run builder
