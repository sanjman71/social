class ApplicationController < ActionController::Base
  protect_from_forgery

  # default application layout
  layout 'application'
end
