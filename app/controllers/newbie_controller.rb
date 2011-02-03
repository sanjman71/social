class NewbieController < ApplicationController
  before_filter :authenticate_user!
  respond_to    :html, :json

  # GET /newbie/favorites
  def favorites
    @user       = current_user
    @action     = params[:action].to_s
    @data_url   = add_favorite_location_path(:format => 'js')
    # next step is newbie plans
    @data_goto  = newbie_plans_path
    @title      = "Favorite Places"
    @step       = 2
    @required   = ['place']
    @button     = "Next"

    # track page
    flash.now[:tracker] = track_page("/newbie/2")

    render(:action => 'steps')
  end

  # GET /newbie/plans
  def plans
    @user       = current_user
    @action     = params[:action].to_s
    @data_url   = add_todo_location_path(:format => 'js')
    @data_goto  = newbie_completed_path
    @title      = "Planned Checkins"
    @step       = 3
    @required   = ['place', 'going']
    @button     = "Done"

    # track page
    flash.now[:tracker] = track_page("/newbie/3")

    render(:action => 'steps')
  end

  # GET /newbie/completed
  def completed
    # track page
    flash[:tracker] = track_page("/newbie/completed")
  end

end
