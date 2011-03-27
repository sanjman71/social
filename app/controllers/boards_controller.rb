class BoardsController < ApplicationController
  before_filter :authenticate_user!

  # GET /
  def index
    # find user's most recent chalkboard
    @chalkboard = Wall.find_by_member(current_user)
    redirect_to(board_path(@chalkboard.id))
  end

  # GET /boards/1
  def show
    @chalkboard = Wall.find(params[:id])
  end

end