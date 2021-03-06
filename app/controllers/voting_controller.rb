class VotingController < ApplicationController
  before_filter :authenticate_user!
  respond_to :html

  # PUT vote/users/1/badges/5/agree|disagree
  def create
    @user   = User.find(params[:user_id])
    @badge  = Badge.find(params[:badge_id]) 
    @voter  = current_user
    @vote   = case params[:vote]
    when 'agree'
      1
    when 'disagree'
      2
    end

    @user.badging_votes.create(:badge => @badge, :voter => @voter, :vote => @vote)
  
    respond_with(@user, :location => user_path(@user))
  end

end
