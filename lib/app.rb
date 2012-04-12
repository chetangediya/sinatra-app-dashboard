require 'sinatra'
require 'haml'
require 'tmdb_party'
require 'twitter'
require 'feedzirra'

class Feed
  
  def initialize(url)
    # instance variables
    @url = url
    @rss = Feedzirra::Feed.fetch_and_parse(@url)
    @tmdb = TMDBParty::Base.new('0b612aa30e25ac5a0ffeb0a743e6511d')
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
    search_results = @tmdb.browse(:query => movie())    
  end
  
  def poster
    poster = search()[0].posters[0].cover_url
  end
  
  def url
    url = @rss.url  
  end
  
  def to_html
    max_description_length = 100
 
    html = "<h4><a href='#{@rss.url}'>#{@rss.title}</a></h4>"
    html << "<small>Updated on #{@rss.entries[0].published.strftime('%m/%d/%Y')}</small>" \
            if @rss.entries[0].published
    html << "<ol>"
  
    @rss.entries.each do |i|
      html << "<li><strong><a href='#{i.url}'>#{i.title}</a></strong><br/>"
      html << "<small>Added on #{i.published.strftime("%m/%d/%Y")} at \
  #{i.published.strftime("%I:%M%p")}</small><br/>" if i.published
      desc_text = i.summary.gsub(/<[^>]+>/,"").squeeze(" ").strip
      if desc_text.length > max_description_length
        desc_text = desc_text[0,max_description_length] + "&hellip;"
      else
        desc_text = i.content
      end
      html << "#{desc_text}"
      html << "</li>"
    end
 
   html << "</ol>"
   html
 end
   

end

class Dashboard < Sinatra::Application

    set :views, settings.root + '/../views'

def get_tweet
  @last_tweet = Twitter.user_timeline("timsalazar", :include_entities => true).first  
end       
  
  get '/' do
    @imdb = Feed.new('http://rss.imdb.com//list/2aXCP-zFqLQ')
    @wp = Feed.new('http://infiniteregress.org/?feed=rss2')
    @tumblr = Feed.new('http://blog.ntimsalazar.com/rss')
    # get_tweet     
    
    haml :index
  end  
        
  get '/stylesheet.css' do
    sass :stylesheet
  end

  post '/movie' do
      @movie = params[:moviename]
      movies = imdb.find_by_title(@movie)
      @title = movies[0][:title]
      @year = movies[0][:year]
      @poster = movies[0][:poster_url]
      @num_results = movies.length - 1
      
      @remade = if movies[0][:title] == movies[1][:title]
        "YES."
      else
        "PROBABLY NOT."
      end
      
      movies.slice!(0)
      @other_movies = movies.map {|movie| movie[:title] + " " + movie[:year]}
      #get_id(:moviename)
      
      haml :movies
  end  
      

end