require 'rubygems'
require 'rack'
require 'rack/contrib'
require 'uri'

require "#{File.dirname __FILE__}/command_dispatch.rb"
require "#{File.dirname __FILE__}/trollop_action.rb"
require "#{File.dirname __FILE__}/sleep.rb"

dispatch = CommandDispatch.new({
  'trollop' => TrollopAction.new do
    opt :flag, 'A flag'
    opt :value, 'A value', :default => 10
  end,
  'sleep' => Sleep.new,
  'inspect_env' => Proc.new { |env,args| env.inspect }
  })

builder = Rack::Builder.new do
  use Rack::CommonLogger

  map '/client' do
    run Rack::File.new 'client'
  end

  map '/cmd' do
    run dispatch
  end
end

Rack::Handler::WEBrick.run builder
