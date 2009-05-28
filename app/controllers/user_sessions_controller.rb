class UserSessionsController < ApplicationController
  layout 'login'
  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash[:notice] = "Login successful!"
      redirect_back_or_default admin_theaters_path
    else
      render :action => :new
    end
  end
end
