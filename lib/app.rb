require 'sinatra'
require 'haml'
require 'imdb_party' 
require 'rss'
 

class Dashboard < Sinatra::Application

    set :views, settings.root + '/../views'

  get '/' do
   rss = RSS::Parser.parse(open('http://rss.imdb.com//list/2aXCP-zFqLQ/').read, false)
   @l = rss.items.last

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