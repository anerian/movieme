class Admin::TheatersController < Admin::BaseController
  
  def index
    @page = params[:page] || 1
    @theaters = Theater.paginate(:page => @page, :order => 'name desc', :per_page => 20)
  end
  
end