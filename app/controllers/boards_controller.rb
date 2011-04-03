class BoardsController < ApplicationController
  before_filter :authenticate_user!

  # GET /boards
  def index
    # find all chalkboards with messages
    @chalkboards = Wall.find_all_by_member(current_user)
  end

  # GET /boards/1
  def show
    @chalkboard = Wall.find(params[:id])
  end

end