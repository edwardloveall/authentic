require "./spec_helper"

class Test::Action < Lucky::Action
  get "/" { text "Doesn't matter" }
end

class Fallback::Action < Lucky::Action
  get "/fallback" { text "Doesn't matter" }
end

describe Authentic do
  it "remembers the requested path if it is a GET " do
    context = ContextHelper.new(path: "/redirect_here").build
    action = Test::Action.new(context, empty_params)
    action.session[:return_to].should be_nil

    Authentic.remember_requested_path(action)

    action.session[:return_to].should eq "/redirect_here"
  end

  it "does not remember the requested path if it isn't a GET " do
    context = ContextHelper.new(method: "POST").build
    action = Test::Action.new(context, empty_params)
    action.session[:return_to].should be_nil

    Authentic.remember_requested_path(action)

    action.session[:return_to].should be_nil
  end

  it "redirects to originally requested path if it is set" do
    context = ContextHelper.new.build
    action = Test::Action.new(context, empty_params)
    action.session[:return_to] = "/redirect_here"

    response = Authentic.redirect_to_originally_requested_path(
      action,
      fallback: Fallback::Action
    )

    response.context.response.headers["Location"].should eq "/redirect_here"
  end

  it "redirects to fallback if return to is not set" do
    context = ContextHelper.new.build
    action = Test::Action.new(context, empty_params)

    response = Authentic.redirect_to_originally_requested_path(
      action,
      fallback: Fallback::Action
    )

    response.context.response.headers["Location"].should eq Fallback::Action.path
  end
end

private def empty_params
  {} of String => String
end
