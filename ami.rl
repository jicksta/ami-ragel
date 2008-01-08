
class RagelGeneratedAMIProtocolStateMachine

  CAPTURES_IN_PROGRESS = {}
  CAPTURED_VARIABLES   = {}
  CAPTURE_CALLBACKS    = {}

  %%{
  	machine ami_protocol_parser;
    
  	carriage_return = "\r";
  	line_feed       = "\n";
  	crlf            = carriage_return line_feed;
    rest_of_line    = (any* -- crlf);
    
    action after_prompt  { after_prompt  }
    action before_prompt { before_prompt }
    action open_version  { begin_capturing:version  }
    action close_version { finish_capturing:version }
    
  	Prompt = "Asterisk Call Manager/" digit+ >open_version "." digit+ %close_version;
    ActionID = "ActionID: " rest_of_line;
    
		Response 	= "Response: ";
		Success		= Response "Success" crlf;
		Pong 			= Response "Pong" crlf;
		Error 		= Response "Error" crlf;
		Events		= Response "Events " ("On" | "Off") crlf;
		Follows 		= Response "Follows" crlf;
    EndFollows 	= "--END COMMAND--" crlf;
    
    
  	main := Prompt >before_prompt crlf @after_prompt;
    
  }%% # %

  attr_reader :version
  def initialize
    capture_callback_for :version do |version|
      @version = version.to_f
    end
  end
  
  def execute_with(data)
    @data = data
    %%{
			variable p        @current_position;
			variable pe       @data_end_position;
			variable cs       @current_state;
			variable act      @most_recent_successful_pattern_match;
			variable data     @data;
			variable tokstart @token_start_position;
			variable tokend   @token_end_position;
			
      write data;  
      write init;  
      write exec;
    }%%
    @data = nil
  end
  alias << execute_with
  
  def begin_capturing(variable_name)
    CAPTURES_IN_PROGRESS[variable_name] = @current_position
  end
  
  def finish_capturing(variable_name)
    start, stop = CAPTURES_IN_PROGRESS.delete(variable_name), @current_position
    return unless start && start < stop
    capture = @data[start...stop]
    CAPTURED_VARIABLES[variable_name] = capture
    CAPTURE_CALLBACKS[variable_name].call(capture) if CAPTURE_CALLBACKS.has_key? variable_name
  end
  
  def before_prompt
    puts "before prompt!"
  end
  
  def after_prompt
    puts "after prompt!!"
  end
  
  private
  
  def capture_callback_for(variable_name, &block)
    CAPTURE_CALLBACKS[variable_name] = block
  end
  
end

class BufferedLineReadingStream
  def initialize(io, recipient, continue_message=:continue_with_line)
    @io, @recipient, @method_name = io, recipient, continue_message
  end
  
  def start!
    loop { @recipient.send(@method_name, @io.readline) } unless finished?
  rescue EOFError
    @finished = true
  end
  
  def finished?
    @finished
  end
end

class ProtocolIrregularity < Exception
end

class VersionNotSentAtSocketCreation < ProtocolIrregularity
  
end