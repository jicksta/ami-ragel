require 'rubygems'
require 'active_support'

require File.join(File.dirname(__FILE__), 'packets.rb')

class AmiStreamParser

  BUFFER_SIZE = 8.kilobytes

  CAPTURED_VARIABLES   = {}
  CAPTURE_CALLBACKS    = {}

  %%{ #%#
  	machine ami_protocol_parser;
    
  	carriage_return = "\r";
  	line_feed       = "\n";
  	crlf            = carriage_return line_feed;
  	stanza_break    = crlf crlf;
    rest_of_line    = (any* -- crlf);
    
    action before_prompt { before_prompt }
    action after_prompt  { after_prompt  }
    action open_version  { begin_capturing_variable  :version }
    action close_version { finish_capturing_variable :version }
    
    action before_key    { begin_capturing_key  }
    action after_key     { finish_capturing_key }
    
    action before_value  { begin_capturing_value  }
    action after_value   { finish_capturing_value }
    
    action error_reason_start { error_reason_start }
    action error_reason_end   { error_reason_end; fgoto main; }
    
    action start_ignoring_syntax_error {
      fhold;
      start_ignoring_syntax_error;
      fgoto error_recovery;
    }
    action end_ignoring_syntax_error {
      end_ignoring_syntax_error;
      fgoto main;
    }
    
    # Executed after a "Respone: Success" or a Pong
    action init_success {
      @current_message = NormalAmiResponse.new
    }
    
    action init_event {
      event_name = finish_capturing_variable :event_name
      @current_message = Event.new event_name
      puts "Instantiated new event"
    }
    
  	Prompt = "Asterisk Call Manager/" digit+ >open_version "." digit+ %close_version crlf;
  	KeyValuePair = (alnum | print)+ >before_key %after_key ": " rest_of_line >before_value %after_value crlf;
  	
  	action message_received { message_received @current_message }
  	
    ActionID = "ActionID: "i rest_of_line;
    
		Response 	= "Response: "i;
		Success		= Response "Success"i %init_success crlf @{ fgoto success; };
    Pong      = Response "Pong"i %init_success crlf;
    Error     = Response "Error"i crlf "Message: "i @error_reason_start rest_of_line crlf crlf @error_reason_end;
    
    # Events		= Response "Events " ("On" | "Off") crlf;
		# Follows 		= Response "Follows" crlf;
    # EndFollows 	= "--END COMMAND--" crlf;
    
    Event     = "Event:"i [ ]* %{begin_capturing_variable:event_name} rest_of_line %init_event crlf @{ fgoto success; };
    
  	main := Prompt? ((((Success | Pong | Event) crlf @message_received) | (Error crlf))) $err(start_ignoring_syntax_error);
    success := KeyValuePair+ crlf @message_received;
    error_recovery := (any* -- stanza_break) stanza_break @end_ignoring_syntax_error; # Skip over everything until we get back to crlf{2}
    
  }%% # %

  def initialize
    capture_callback_for :version do |version|
      @version = version.to_f
    end
    
    @data = ""
    @current_pointer = 0
    %%{
      # All other variables become local, letting Ruby garbage collect them. This
      # prevents us from having to manually reset them.
      
			variable data @data;
      variable p @current_pointer;
			variable pe @data_ending_pointer;
			variable cs @current_state;
			variable tokstart @token_start;
			variable stack @stack;
			variable tokend @token_end;
			variable act @ragel_act;
			
			write data nofinal;
      write init;
    }%%
  end
  
  def <<(new_data)
    p [:starting, {:current_pointer => @current_pointer, :data => @data, :ending => @data_ending_pointer}]
    if new_data.size + @data.size > BUFFER_SIZE
      @data.slice! 0...new_data.size
      @current_pointer = @data.size
    end
    @data << new_data
    @data_ending_pointer = @data.size
    resume!
    p [:ending, {:current_pointer => @current_pointer, :data => @data, :ending => @data_ending_pointer}]
  end
  
  def resume!
    %%{ write exec; }%%
  end
  
  private
  
  def begin_capturing_variable(variable_name)
    @start_of_current_capture = @current_pointer
  end
  
  def finish_capturing_variable(variable_name)
    start, stop = @start_of_current_capture, @current_pointer
    return :failed if !start || start > stop
    capture = @data[start...stop]
    CAPTURED_VARIABLES[variable_name] = capture
    CAPTURE_CALLBACKS[variable_name].call(capture) if CAPTURE_CALLBACKS.has_key? variable_name
    capture
  end
  
  # This method must do someting with @current_message or it'll be lost.
  def message_received(current_message)
    current_message
  end
  
  def begin_capturing_key
    @current_key_position = @current_pointer
  end
  
  def finish_capturing_key
    @current_key = @data[@current_key_position...@current_pointer]
  end
  
  def begin_capturing_value
    @current_value_position = @current_pointer
  end
  
  def finish_capturing_value
    @current_value = @data[@current_value_position...@current_pointer]
    add_pair_to_current_message
  end
  
  def error_reason_start
    @error_reason_start = @current_pointer
  end
  
  def error_reason_end
    ami_error! @data[@error_reason_start...@current_pointer]
    @error_reason_start = nil
  end
  
  def add_pair_to_current_message
    @current_message[@current_key] = @current_value
    reset_key_and_value_positions
  end
  
  def reset_key_and_value_positions
    @current_key, @current_value, @current_key_position, @current_value_position = nil
  end
  
  def start_ignoring_syntax_error
    @current_syntax_error_start = @current_pointer
  end
  
  def end_ignoring_syntax_error
    syntax_error! @data[@current_syntax_error_start...@current_pointer]
    @current_syntax_error_start = nil
  end
  
  def capture_callback_for(variable_name, &block)
    CAPTURE_CALLBACKS[variable_name] = block
  end
  
  def ami_error!(reason)
    puts "errroz! #{reason}"
    # raise "AMI Error: #{reason}"
  end
  
  def syntax_error!(ignored_chunk)
    p "Ignoring this: #{ignored_chunk}"
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
