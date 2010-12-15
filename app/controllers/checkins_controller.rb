class CheckinsController < ApplicationController
  before_filter       :authenticate_user!, :only => [:index]
  before_filter       :find_user, :only => [:index]
  skip_before_filter  :check_beta, :only => :poll
  respond_to          :html, :json, :js

  # GET /users/1/checkins
  # GET /users/1/checkins/geo:1.23..-23.89/radius:10?limit=5&without_checkin_ids=1,5,3&max_user_checkins=3
  # GET /users/1/checkins/city:chicago?limit=5&without_checkin_ids=1,5,3
  # GET /users/1/checkins/all|friends|guys|gals|my|others|outlately
  # GET /users/1/checkins?order=default
  def index
    # parse general parameters
    @max_user_checkins    = params[:max_user_checkins] ? params[:max_user_checkins].to_i : 5
    @without_checkin_ids  = params[:without_checkin_ids] ? params[:without_checkin_ids].split(',').map(&:to_i).uniq.sort : nil
    @grouped_user_ids     = Checkin.where(:id => @without_checkin_ids).select(:user_id).collect{ |o| o.user_id.to_i }.group_by(&:to_i) rescue {}
    # partition users into exclude, unweight lists based on checkin counts
    @unweight_user_ids    = Set.new
    @without_user_ids     = Set.new
    @grouped_user_ids.keys.each do |user_id|
      if @grouped_user_ids[user_id].size >= @max_user_checkins
        # exclude user
        @without_user_ids.add(user_id)
      else
        # unweight user
        @unweight_user_ids.add(user_id)
      end
    end
    @search               = params[:search] ? params[:search].to_s : 'all'
    @method               = "search_#{@search}_checkins"
    @order                = [:sort_closer_locations, :sort_checkins_past_week,
                             {:sort_unweight_users => @unweight_user_ids.to_a.sort}]
    @limit                = params[:limit] ? params[:limit].to_i : 2**30
    @options              = Hash[:without_checkin_ids => @without_checkin_ids,
                                 :without_user_ids => @without_user_ids.to_a.sort,
                                 :order => @order, :limit => @limit, :klass => Checkin]
    case
    when params[:geo]
      @lat, @lng    = find_lat_lng
      @radius       = find_radius
      @options.update(:geo_origin => [@lat.radians, @lng.radians],
                      :geo_distance => 0.0..@radius.miles.meters.value)
      @checkins     = @user.send(@method, @options)
    when params[:city]
      @city         = find_city
      @radius       = find_radius
      @options.update(:geo_origin => [@city.lat.radians, @city.lng.radians],
                      :geo_distance => 0.0..@radius.miles.meters.value)
      @checkins     = @user.send(@method, @options)
    else
      @checkins     = @user.send(@method, @options)
    end

    respond_to do |format|
      format.html
      format.js
      format.json do
        render :json => @checkins.to_json
      end
    end
  end

  protected

  def find_user
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
  end

end