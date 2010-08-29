class CheckinsController < ApplicationController
  before_filter :authenticate_user!

  def index
    @checkins = current_user.checkins
  end

end