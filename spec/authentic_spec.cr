require "./spec_helper"

class Test::Action < Lucky::Action
  get "/" { text "Doesn't matter" }
end

describe Authentic do
  it "remembers the requested path if it is a GET " do
    context = ContextHelper.new(path: "/direct_here_after_sign_in").build
    action = Test::Action.new(context, empty_params)
    action.session[:return_to].should be_nil

    Authentic.remember_requested_path(action)

    action.session[:return_to].should eq "/direct_here_after_sign_in"
  end

  it "does not remember the requested path if it isn't a GET " do
    context = ContextHelper.new(method: "POST").build
    action = Test::Action.new(context, empty_params)
    action.session[:return_to].should be_nil

    Authentic.remember_requested_path(action)

    action.session[:return_to].should be_nil
  end
end

private def empty_params
  {} of String => String
end
