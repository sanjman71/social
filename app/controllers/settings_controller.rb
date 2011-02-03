class SettingsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_user, :only => [:show, :update]

  privilege_required 'manage users', :only => [:show, :update], :on => :user

  # GET /settings
  # GET /newbie/settings
  def show
    @newbie = request.fullpath.match(/^\/newbie/)

    if @newbie
      # track page
      flash.now[:tracker] = track_page("/newbie/1")
      # set next page
      @goto_path = newbie_favorites_path
    end
  end

  # PUT /settings
  def update
    if @user.update_attributes(params[:user])
      User.log("[user:#{@user.id}] #{@user.handle} updated #{params[:user].inspect}")
      flash[:notice] = "Profile updated"
    else
      flash[:error]  = ["There was an error updating your profile"]
      flash[:error] += Array(@user.errors)
    end
    redirect_back_to(root_path)
  end

  protected

  def find_user
    @user = current_user
  end

end