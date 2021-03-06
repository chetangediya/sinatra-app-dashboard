require 'sinatra'
require 'haml'
require 'tmdb_party'
require 'twitter'
require 'feedzirra'
require 'instagram'
require_relative 'keys.rb'

class Feeder
  
  def initialize(url)
    # instance variables
    @url = url
    @rss = Feedzirra::Feed.fetch_and_parse(@url)
    @tmdb = TMDBParty::Base.new(Keys.tmdb_key)
  end

  def inspect
    "RSS feed from #{@url}"
  end

  def title
    title = @rss.entries[0].title
  end

  def length
    length = @rss.entries.length    
  end

  def movie
    movie = @rss.entries.last.title
  end
  
  def search
    @movie = movie()
    tmdb_result = @tmdb.browse(:query => @movie)
  end  

  def poster
    poster = search().last.posters[0].cover_url
  end
  
  def url
    url = @rss.url  
  end
  
  def to_html
    max_description_length = 100
    min_title_length = 0
    most_recent_post = @rss.entries.first
 
    html = "<h3><a href='#{@rss.url}'>#{@rss.title}</a></h3>"
    html << "<span class='white label'>on #{@rss.entries[0].published.strftime('%m/%d/%Y')}</span>" \
      if @rss.entries[0].published
        if not "#{most_recent_post.content}".include? "#{most_recent_post.title}"
          html << "<h5>#{most_recent_post.title}</h5>"
        end
        if not "#{most_recent_post.content}".empty? 
          html << "<p>#{most_recent_post.content}</p>"
        end
        if not @url.include? "infiniteregress.org"
          html << "<p>#{most_recent_post.summary}</p>"
        end
    html
      end
  end
   
class Dashboard < Sinatra::Application

set :views, settings.root + '/../views'

enable :sessions

CALLBACK_URL = "http://localhost:9393/oauth/callback"

Instagram.configure do |config|
  config.client_id = Keys.client_id
  config.client_secret = Keys.client_secret
end

get "/instagram" do
  '<a href="/oauth/connect">Connect with Instagram</a>'
end

get "/oauth/connect" do
  redirect Instagram.authorize_url(:redirect_uri => CALLBACK_URL)
end

get "/oauth/callback" do
  response = Instagram.get_access_token(params[:code], :redirect_uri => CALLBACK_URL)
  session[:access_token] = response.access_token
  redirect "/"
end
    
def get_tweet
  @last_tweet = Twitter.user_timeline("timsalazar", :include_entities => true).first 
end       

def get_instagram
  client = Instagram.client(:access_token => session[:access_token])
  user = client.user
  last_photo = client.user_recent_media.first

  html = "<h3>Here's #{user.username}'s most recent Instagram</h3>"
  html << "<img src='#{last_photo.images.thumbnail.url}'>"

  html 
end

def autolink_urls(tweet)
  r = /(^|\s)@([a-z0-9_]+)/i
  tweet.text.gsub /((https?:\/\/|www\.)([-\w\.]+)+(:\d+)?(\/([\w\/_\.]*(\?\S+)?)?)?)/, %Q{<a href="\\1">\\1</a>}
  tweet.text.gsub(r){|x| "#{$1}<a href=\"http://www.twitter.com/#{$2}\">@#{$2}<a/>"}
end
        
  get '/' do
    @imdb = Feeder.new('http://rss.imdb.com//list/2aXCP-zFqLQ')
    @wp = Feeder.new('http://infiniteregress.org/?feed=rss2')
    @lino = Feeder.new('http://lino.infiniteregress.org/?feed=rss2')
    @tumblr = Feeder.new('http://blog.ntimsalazar.com/rss')    
    @tweet = autolink_urls(get_tweet)
    @instagram = get_instagram
    @quora = Feeder.new('http://www.quora.com/N-Timothy-Salazar/rss')
    @instapaper = Feeder.new('http://www.instapaper.com/rss/2661/hINCyLmQPYJPwTPWSVVpo05Utk')
    haml :index
  end  
        
  get '/stylesheet.css' do
    sass :stylesheet
  end



      

end