require_relative 'snare'
require 'test/unit'
require 'rack/test'

set :environment, :test

class SnareTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_create_new_node
    post '/a_new_site/n:a_new_node'
    assert last_response.ok?
    assert_equal '{"user":"test","site":"a_new_site","node":"a_new_node"}', last_response.body
  end

  def test_get_node
    #setup (will separate later)
    post '/a_new_site/n:a_new_node'

    get '/a_new_site/n:a_new_node'
    assert last_response.ok?
    assert_equal '{"title":"a_new_node","site":"a_new_site","entries":"0","user":"test"}', last_response.body
  end

  def test_delete_node
    delete '/a_new_site/n:a_new_node'
    assert last_response.ok?
    assert_equal '{"user":"test","site":"a_new_site","node":"a_new_node"}', last_response.body
  end
end