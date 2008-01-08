require File.join(File.dirname(__FILE__), "spec_helper")
require File.join(File.dirname(__FILE__), *%w[.. ami.rb])

# MUST ALWAYS SEPARATE THE COLONS WITH WHITESPAC
# TEST THAT IT CAN PARSE EVENTS

context "Establishing a socket" do
  
  include AmiProtocolTestHelper
  
  it "should read the AMI version at the beginning" do
    sample_version = 1.0
    parser_with(a_socket_sending_only("Asterisk Version: #{sample_version}\r\n")).version.should.equal sample_version
  end
  
  it "should raise an error when the version is not there" do
    the_following_code {
      parser_with(a_socket_sending_only("Asterisk Version: 1.0\r\n")).version.should.not.be.nil
    }.should.not.raise
  end
end

context "Reading of an action" do
  
  include AmiProtocolTestHelper
  
  it "should handle a 'Response: Follows' action properly" do

    multi_line_response_body = %{Ragel is a software development tool that allows user actions to
    be embedded into the transitions of a regular expression’s corresponding state machine,
    eliminating the need to switch from the regular expression engine and user code execution
    environment and back again.}

    multi_line_response = format_newlines <<-RESPONSE
ActionID: 123
Response: Follows
#{multi_line_response_body}
--END COMMAND--
RESPONSE
    parser = parser_with a_socket_sending_only(multi_line_response)
    
    # CONCEPTUAL DILEMMA! HOW DOES THE PARSER SEND BACK RESPONSES?
    parser.wait_for_next_action.body.should == multi_line_response_body
  end
  
end

context "BufferedLineReadingStream" do
  
  include AmiProtocolTestHelper
  
  it "lines retain the trailing whitespace" do
    read_lines = []
    recipient  = message_recipient { |line| read_lines << line }
    sample_socket_data = "a\r\nm\r\ni\r\n\r\nf\r\nt\r\nw\r\n\r\n"
    line_reader = line_reader_for(a_socket_sending_only(sample_socket_data), recipient)
    line_reader.start!
    read_lines.should == ["a\r\n", "m\r\n", "i\r\n", "\r\n", "f\r\n", "t\r\n", "w\r\n", "\r\n"]
  end
  
end

context "AmiProtocolTestHelper" do
  
  include AmiProtocolTestHelper
  
  it "should only replace newlines not preceded by carriage returns" do
    before, after = "   i am\n  on a line\r\nkthxbai\n",
                    "   i am\r\n  on a line\r\nkthxbai\r\n"
    format_newlines(before).should == after
  end
end

BEGIN {
  module AmiProtocolTestHelper
  
    def format_newlines(string)
      # HOLY FUCK THIS IS UGLY
      tmp_replacement = random_string
      string.gsub("\r\n", tmp_replacement).
             gsub("\n", "\r\n").
             gsub(tmp_replacement, "\r\n")
    end
 
    def parser_with(stream)
      RagelGeneratedAMIProtocolStateMachine.new
    end
    
    def line_reader_for(stream, line_handler)
      BufferedLineReadingStream.new stream, line_handler
    end
    
    def action_proxy_with_mock_socket_sending(&block)
      
    end
    
    def a_socket_sending_only(data)
      StringIO.new data
    end
    
    def message_recipient(&block)
      returning Object.new do |obj|
        obj.meta_def(:continue_with_line) do |data|
          block.call data
        end
      end
    end
    
    private
    
    def random_string
      (rand(1_000_000_000_000) + 1_000_000_000).to_s
    end
  end
}
