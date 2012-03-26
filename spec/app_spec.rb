require 'app'
require 'rspec'
require 'rack/test' 

set :environment, :test

describe "Dashboard" do
  include Rack::Test::Methods

  def app
    Dashboard
  end

  it "load the last rss item from IMDB" do

    get "/"
    response.should be_successful
    
  end


end
