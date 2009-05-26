class TheatersController < ApplicationController
  
  def index
    @theaters = Theater.nearby(params[:lat].to_f, params[:lng].to_f)

    @movies = Movie.find(*@theaters.map{|t|t.shows.map{|s|s.movie_id}}.flatten)
  end
  
end
