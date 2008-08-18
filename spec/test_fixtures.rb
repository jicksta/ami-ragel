require File.dirname(__FILE__) + "/spec_helper"

context "The fixture method" do
  it "should properly extract a path of stuff" do
    fixture("login/standard/client").should.be.kind_of OpenStruct
  end
  
  it "should properly extract replace template fixture values" do
    standard_login = fixture("login/standard/client")
    standard_login.secret.should.be.kind_of String
    %w[on off].should.include(standard_login.events)
  end
  
end