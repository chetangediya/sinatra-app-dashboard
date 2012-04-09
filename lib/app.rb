require 'sinatra'
require 'haml'
require 'rss'
require 'tmdb_party'
require 'twitter'

class Feed
  
  def initialize(url)
    # instance variables
    api_key = '0b612aa30e25ac5a0ffeb0a743e6511d'
    @url = url
    @rss = RSS::Parser.parse(open(@url).read, false)
    @tmdb = TMDBParty::Base.new(api_key)
  end

  def title
    title = @rss.items[0].title
  end
 
  def movie
    movie = @rss.items.last.title  
  end  
  
  def poster
    results = @tmdb.search(movie)
    poster = results[0].posters[0].cover_url    
  end
  
  def url
    url = @rss.channel.link  
  end
  
  def to_html
    max_description_length = 100
  
    html = "<h4><a href='#{@rss.channel.link}'>#{@rss.channel.title}</a></h4>"
    html << "<small>Updated on #{@rsschannel.date.strftime('%m/%d/%Y')}</small>" \
            if @rss.channel.date
    html << "<p>#{@rss.channel.description}</p>"
    html << "<ol>"
  
    @rss.channel.items.each do |i|
      html << "<li><strong><a href='#{i.link}'>#{i.title}</a></strong><br/>"
      html << "<small>Added on #{i.date.strftime("%m/%d/%Y")} at \
  #{i.date.strftime("%I:%M%p")}</small><br/>" if i.date
      desc_text = i.description.gsub(/<[^>]+>/,"").squeeze(" ").strip
      if desc_text.length > max_description_length
        desc_text = desc_text[0,max_description_length] + "&hellip;"
      else
        desc_text = i.content_encoded
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