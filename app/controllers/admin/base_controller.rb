class Admin::BaseController < ApplicationController
  layout 'admin'
  
  filter_parameter_logging :password, :password_confirmation
  helper_method :current_user_session, :current_user
  
  before_filter :require_user
end