require "./spec_helper"

class Test::Action < Lucky::Action
  get "/" { text "Doesn't matter" }
end

describe Authentic do
  it "remembers the requested path if it is a GET " do
    action = Test::Action.new
    action.session[:return_to].should be_nil

    Authentic.remember_requested_path(action)

    action.session[:return_to].should eq "/direct_here_after_sign_in"
  end
end
