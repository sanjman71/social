class BoardsController < ApplicationController
  before_filter :authenticate_user!

  # GET /
  def index
    # find user's most recent chalkboard
    @chalkboard = Wall.find_by_member(current_user)
  end
  
end