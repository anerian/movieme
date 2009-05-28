class Admin::TheatersController < Admin::BaseController
  
  def index
    @page = params[:page] || 1
    @theaters = Theater.paginate(:page => @page, :order => 'name desc', :per_page => 20)
  end
  
  def edit
    @theater = Theater.find params[:id]
  end
  
  def update
    @theater = Theater.find params[:id]

    if @theater.update_attributes(params[:theater])
      flash[:success] = "Theater saved!" if flash[:success].blank?
      redirect_to edit_admin_theater_path(@theater)
      return false
    end
    
    flash.now[:error] = "Error updating theater!" if flash.now[:error].blank?
    
    render :action => 'edit'
  end
  
end