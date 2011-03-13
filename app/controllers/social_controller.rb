class SocialController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_user

  # GET /
  def index
    # @user initialized in before_filter
    
    # find users out now
    @users_out_now        = Realtime.find_users_out(:map_ids => true)
    # find friends out using intersection of users out now and user friends
    @friends_out_now      = @users_out_now.keys & @user.friend_set
    @friends_out_now      = @friends_out_now.inject(ActiveSupport::OrderedHash.new) do |hash, user_id|
      user     = User.find(user_id)
      checkins = Checkin.find(@users_out_now[user_id])
      hash[user] ||= []
      hash[user].concat(checkins)
      hash
    end

    # friends out recently, exclude checkins from friends out now
    @timestamp_recent     = 2.days.ago
    @friends_checkins     = Checkin.where(:checkin_at.gt => @timestamp_recent).joins(:user).
                                    where(:user => {:id => @user.friend_set}).order("checkin_at desc")
    if @friends_checkins.empty? and enabled(:fill_home_checkins)
      @friends_checkins = Checkin.joins(:user).
                                  where(:user => {:id => @user.friend_set}).order("checkin_at desc").
                                  limit(5)
    end

    # map friends to checkins
    @friends_out_recently = @friends_checkins.inject(ActiveSupport::OrderedHash.new) do |hash, checkin|
      hash[checkin.user] ||= []
      hash[checkin.user].push(checkin)
      hash
    end

    # following
    @following      = User.find(@user.following, :order => 'member desc, member_at asc')
    @following_ids  = @following.collect(&:id)
  end

  def find_user
    @user = current_user
  end

end