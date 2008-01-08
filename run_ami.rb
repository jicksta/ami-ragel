require File.join(File.dirname(__FILE__), 'ami.rb')

parser = RagelGeneratedAMIProtocolStateMachine.new

packets = ["Asterisk Call Manager/1.0\r\n"] #,"Action: Ping\r\n", ]

packets.each do |packet|
  parser << packet
end

p parser.version
