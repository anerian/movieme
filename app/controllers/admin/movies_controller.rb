class Admin::MoviesController < Admin::BaseController
  
  def index
    @page = params[:page] || 1
    @movies = Movie.paginate(:page => @page, :order => 'title asc', :per_page => 20)
  end
  
  def edit
    @movie = Movie.find params[:id]
  end
  
  def update
    @movie = Movie.find params[:id]

    if @movie.update_attributes(params[:movie])
      flash[:success] = "Movie saved!" if flash[:success].blank?
      redirect_to edit_admin_movie_path(@movie)
      return false
    end
    
    flash.now[:error] = "Error updating movie!" if flash.now[:error].blank?
    
    render :action => 'edit'
  end
  
  def destroy
    @movie = Theater.find params[:id]
    @movie.destroy if @movie
    
    redirect_to admin_movies_path
  end
  
end