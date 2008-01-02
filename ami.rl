class RagelGeneratedAMIProtocolStateMachine

  # To decouple the state machine with the socket layer, there are actually
  # two Ragel state machines. One simply reads lines from the socket while
  # the other parses the line.
	def continue_with_line
	  
	end
  
  def version
    raise NotImplementedError
  end
  
	%%{
	
		machine AsteriskManagerInterfaceProtocolParser;
	
		carriage_return = "\r";
		new_line        = "\n";
		line_break      = carriage_return  new_line;
	
		# key_value_pair = ([^:] -- line_break)+ /:( )*+/ any*;
	
	}%%
	
end

class BufferedLineReadingStream
  def initialize(io, recipient, continue_message=:continue_with_line)
    @io, @recipient, @method_name = io, recipient, continue_message
  end
  
  def start!
    loop { @recipient.send(@continue_message, @io.readline) }
  end
end

class ProtocolIrregularity < Exception
end

class VersionNotSentAtSocketCreation < ProtocolIrregularity
  
end