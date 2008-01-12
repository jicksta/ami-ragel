require File.join(File.dirname(__FILE__), 'ami.rb')

parser = RagelGeneratedAMIProtocolStateMachine.new

packets = ["Asterisk Call Manager/1.0\r\n",
           "Response: Success\r\nMessage: Authentication accepted\r\n",
           "Response: Pong\r\n",
           "Response: Pong\r\nActionID: 1337\r\n"]

packets.each do |packet|
  parser << packet
end