require 'sinatra'
require 'haml'
require 'tmdb_party'
require 'twitter'
require 'feedzirra'
require 'instagram'

class Feeder
  
  def initialize(url)
    # instance variables
    @url = url
    @rss = Feedzirra::Feed.fetch_and_parse(@url)
    @tmdb = TMDBParty::Base.new('0b612aa30e25ac5a0ffeb0a743e6511d')
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
 
    html = "<h2>The most recent post from <a href='#{@rss.url}'>#{@rss.title}</a></h2>"
    html << "<small>on #{@rss.entries[0].published.strftime('%m/%d/%Y')}</small><br/>" \
      if @rss.entries[0].published
        if not "#{most_recent_post.content}".include? "#{most_recent_post.title}"
          html << "#{most_recent_post.title}"
        end
        if not "#{most_recent_post.content}".empty? 
          html << "#{most_recent_post.content}"
        end
        if not @url.include? "infiniteregress.org"
          html << "#{most_recent_post.summary}"
        end
    html
      end
  end
   
class Dashboard < Sinatra::Application

set :views, settings.root + '/../views'

enable :sessions

CALLBACK_URL = "http://localhost:9393/oauth/callback"

Instagram.configure do |config|
  config.client_id = "b3e8dd1c56724cd9a8f7248dea717865"
  config.client_secret = "5b530ad6abab4a2ca3f7758fc685743b"
end

@tmdb = TMDBParty::Base.new('0b612aa30e25ac5a0ffeb0a743e6511d')

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

  html = "<h2>Here's #{user.username}'s most recent Instagram</h2>"
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
#    @tweet = autolink_urls(get_tweet)
    @instagram = get_instagram
    @quora = Feeder.new('http://www.quora.com/N-Timothy-Salazar/rss')
    @instapaper = Feeder.new('http://www.instapaper.com/rss/2661/hINCyLmQPYJPwTPWSVVpo05Utk')
    haml :index
  end  
        
  get '/stylesheet.css' do
    sass :stylesheet
  end



      

end