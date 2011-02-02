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

    @notice     = ["Checkins are the way you build your profile on Outlately."]
    @notice     += [""]
    @notice     += ["Step 2: Tell us a place you love going."]
    flash.now[:notice] = @notice

    # track page
    flash.now[:tracker] = track_page("/newbie/2")

    render(:action => 'newbie')
  end

  # GET /newbie/plans
  def plans
    @user       = current_user
    @action     = params[:action].to_s
    @data_url   = add_todo_location_path(:format => 'js')
    @data_goto  = newbie_completed_path
    @title      = "Planned Checkins"

    @notice     = ["By planning a checkin, you enable people to express interest in meeting up or buying you a drink.
                    You can always say 'no thanks' if you're not interested."]
    @notice     += [""]
    @notice     += ["Step 3: Tell us a place you plan to go."]
    flash.now[:notice] = @notice

    # track page
    flash.now[:tracker] = track_page("/newbie/3")

    render(:action => 'newbie')
  end

  # GET /newbie/completed
  def completed
    # track page
    flash[:tracker] = track_page("/newbie/completed")
    redirect_to(root_path) and return
  end

end
