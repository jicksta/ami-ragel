require File.join(File.dirname(__FILE__), "spec_helper")
require File.join(File.dirname(__FILE__), *%w[.. ami.rb])

context "Establishing a socket" do
  
  include AmiProtocolTestHelper
  
  it "should read the AMI version at the beginning" do
    parser_with(a_socket_sending_only("Asterisk Version: 1.0\r\n")).version.should.not.be.nil
  end
  
  it "should raise an error when the version is not there" do
    the_following_code {
      parser_with(a_socket_sending_only("Asterisk Version: 1.0\r\n")).version.should.not.be.nil
    }.should.raise VersionNotSentAtSocketCreation
  end
end

context "Reading of an action" do
  
end

context "BufferedLineReadingStream" do
  
  include AmiProtocolTestHelper
  
  it "lines retain the trailing whitespace" do
    read_lines = []
    recipient  = message_recipient { |line| read_lines << line }
    sample_socket_data = "a\r\nm\r\ni\r\n\r\nf\r\nt\r\nw"
    line_reader = line_reader_for(a_socket_sending_only(sample_socket_data), recipient)
    line_reader.start!
    read_lines.should == ["a\r\n", "m\r\n", "i\r\n", "\r\n", "f\r\n", "t\r\n", "w\r\n", "\r\n"]
  end
  
end

BEGIN {
  module AmiProtocolTestHelper
 
    def parser_with(stream)
      RagelGeneratedAMIProtocolStateMachine.new
    end
    
    def line_reader_for(stream, line_handler)
      BufferedLineReadingStream.new stream, line_handler
    end
    
    def a_socket_sending_only(data)
      StringIO.new data
    end
    
    def message_recipient(&block)
      returning Object.new do |obj|
        class << obj
          def continue_with_line(data)
            block.call data
          end
        end
      end
    end
    
  end
}
