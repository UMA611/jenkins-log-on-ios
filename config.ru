require 'rubygems'
require 'thin'
require 'rack'
require 'rack/websocket'
require 'sinatra'
require './app'

# Set service point for the websockets. This way we can run both web sockets and sinatra on the same server and port number.
map '/log' do 
	run WebSocketApp.new
end

# This delegates everything other route not defined above to the Sinatra app.
map '/' do
	run SinatraApp
end
