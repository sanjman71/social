class SettingsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_user, :only => [:show, :update]

  privilege_required 'manage users', :only => [:show, :update], :on => :user

  # GET /settings
  def edit
    # @user initialized in before filter
    @show_handle_message = params[:handle].to_i == 1
  end

  # PUT /settings
  def update
    if @user.update_attributes(params[:user])
      User.log("[user:#{@user.id}] #{@user.handle} updated #{params[:user].inspect}")
      flash[:notice] = "Profile updated"
    else
      flash[:error]  = "There was an error updating your profile"
    end
    redirect_back_to(root_path)
  end

  protected

  def find_user
    @user = current_user
  end

end