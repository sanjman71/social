class CheckinsController < ApplicationController
  before_filter :authenticate_user!

  def index
    # group checkins by source
    @checkins = current_user.checkins.group_by(&:source_type)
  end

end