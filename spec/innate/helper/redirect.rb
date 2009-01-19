require 'spec/helper'

class SpecRedirectHelper
  include Innate::Node

  def index
    self.class.name
  end

  def noop
    'noop'
  end

  def redirection
    redirect :index
  end

  def double_redirection
    redirect :redirection
  end

  def redirect_referer_action
    redirect_referer
  end

  def no_actual_redirect
    catch(:redirect){ redirection }
    'no_actual_redirect'
  end

  def no_actual_double_redirect
    catch(:redirect){ double_redirection }
    'no_actual_double_redirect'
  end

  def redirect_method
    redirect r(:noop)
  end

  def absolute_redirect
    redirect 'http://localhost:7000/noop'
  end

  def loop
    respond 'no loop'
    'loop'
  end

  def respond_with_status
    respond 'not found', 404
  end

  def redirect_unmodified
    raw_redirect '/noop'
  end
end

Innate.setup_dependencies
Innate.setup_middleware

describe Innate::Helper::Redirect do
  @uri = 'http://localhost:7000'

  should 'retrieve index' do
    Innate::Mock.get('/').body.should =='SpecRedirectHelper'
  end

  should 'redirect' do
    got = Innate::Mock.get("#@uri/redirection")
    got.status.should == 302
    got.headers['Location'].should == "#@uri/index"
  end

  should 'redirect twice' do
    got = Innate::Mock.get("#@uri/double_redirection")
    got.status.should == 302
    got.headers['Location'].should == "#@uri/redirection"
  end

  should 'redirect to referer' do
    got = Innate::Mock.get("#@uri/redirect_referer_action", 'HTTP_REFERER' => '/noop')
    got.status.should == 302
    got.headers['Location'].should == "#@uri/noop"
  end

  should 'use #r' do
    got = Innate::Mock.get("#@uri/redirect_method")
    got.status.should == 302
    got.headers['Location'].should == "#@uri/noop"
  end

  should 'work with absolute uris' do
    got = Innate::Mock.get("#@uri/absolute_redirect")
    got.status.should == 302
    got.headers['Location'].should == "#@uri/noop"
  end

  should 'support #respond' do
    got = Innate::Mock.get("#@uri/loop")
    got.status.should == 200
    got.body.should == 'no loop'
  end

  should 'support #respond with status' do
    got = Innate::Mock.get("#@uri/respond_with_status")
    got.status.should == 404
    got.body.should == 'not found'
  end

  should 'redirect without modifying the target' do
    got = Innate::Mock.get("#@uri/redirect_unmodified")
    got.status.should == 302
    got.headers['Location'].should == '/noop'
  end
end
