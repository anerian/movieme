class TheatersController < ApplicationController
  
  def index
    @zip = params[:zip]
    
    latitude, longitude = @zip.blank? ? [params[:lat].to_f, params[:lng].to_f] : ZipCode.find_by_code(@zip).coordinate
      
    @theaters = Theater.nearby(latitude, longitude)

    @movies = Movie.find(*@theaters.map{|t|t.shows.map{|s|s.movie_id}}.flatten) rescue []
  end
  
end
