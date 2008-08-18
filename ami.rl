require 'rubygems'
require 'active_support'

require File.join(File.dirname(__FILE__), 'packets.rb')

class AmiStreamParser

  CAPTURED_VARIABLES   = {}
  CAPTURE_CALLBACKS    = {}

  %%{ #%#
  	machine ami_protocol_parser;
    
  	carriage_return = "\r";
  	line_feed       = "\n";
  	crlf            = carriage_return line_feed;
    rest_of_line    = (any* -- crlf);
    
    action before_prompt { before_prompt }
    action after_prompt  { after_prompt  }
    action open_version  { begin_capturing_variable  :version }
    action close_version { finish_capturing_variable :version }
    
    action before_key    { begin_capturing_key  }
    action after_key     { finish_capturing_key }
    
    action before_value  { begin_capturing_value  }
    action after_value   { finish_capturing_value }
    
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
  	
    ActionID = "ActionID: " rest_of_line;
    
		Response 	= "Response: ";
		Success		= Response "Success" %init_success crlf @{ fgoto success; };
    Pong      = Response "Pong" %init_success crlf;
    
    Event     = "Event:" [ ]* %{begin_capturing_variable:event_name} rest_of_line %init_event crlf @{ fgoto success; };
    
		# Error 		= Response "Error" crlf;
		# Events		= Response "Events " ("On" | "Off") crlf;
		# Follows 		= Response "Follows" crlf;
    # EndFollows 	= "--END COMMAND--" crlf;
    
  	main := Prompt? (Success | Pong | Event crlf) @message_received;
    success := KeyValuePair+ crlf @message_received;
    
  }%% # %

  attr_reader :version
  def initialize
    capture_callback_for :version do |version|
      @version = version.to_f
    end
  end
  
  def execute_with(data)
    
    # TODO: These are only instance variable so other methods can access them.
    # It should probably be designed such that the other methods request this
    # as an argument.
    @data, @current_position = data, 0
    
    %%{
      # All other variables become local, letting Ruby garbage collect them. This
      # prevents us from having to manually reset them.
      
			variable p    @current_position;
			variable data @data;
			
      write data;
      write init;
      write exec;
    }%%
  end
  alias << execute_with
  
  private
  
  def begin_capturing_variable(variable_name)
    @start_of_current_capture = @current_position
  end
  
  def finish_capturing_variable(variable_name)
    start, stop = @start_of_current_capture, @current_position
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
    @current_key_position = @current_position
  end
  
  def finish_capturing_key
    @current_key = @data[@current_key_position...@current_position]
  end
  
  def begin_capturing_value
    @current_value_position = @current_position
  end
  
  def finish_capturing_value
    @current_value = @data[@current_value_position...@current_position]
    add_pair_to_current_message
  end
  
  def add_pair_to_current_message
    @current_message[@current_key] = @current_value
    reset_key_and_value_positions
  end
  
  def reset_key_and_value_positions
    @current_key, @current_value, @current_key_position, @current_value_position = nil
  end
  
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
