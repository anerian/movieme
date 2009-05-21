class TheatersController < ApplicationController
  
  def index
    @theaters = Theater.showtimes(params[:postal_code])
  end
  
end
