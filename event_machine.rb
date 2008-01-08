require 'rubygems'
require 'event_machine'

module EchoServer
  def receive_data(data)
    send_data ">> You Sent: #{data}\n"
    close_connection if data =~ /quit/i
  end
end

EventMachine.start_server '0.0.0.0', 1337, EchoServer