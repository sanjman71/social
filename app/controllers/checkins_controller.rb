class CheckinsController < ApplicationController
  before_filter       :authenticate_user!, :only => [:index, :search]
  before_filter       :find_user, :only => [:search]
  skip_before_filter  :check_beta, :only => :poll
  respond_to          :html, :json, :js

  privilege_required  'admin', :only => [:index]

  def page_size
    20
  end

  # GET /checkins
  def index
    @page     = params[:page] ? params[:page].to_i : 1
    @limit    = params[:limit] ? params[:limit].to_i : page_size
    @checkins = Checkin.order("checkin_at desc").paginate(:page => @page, :per_page => @limit)
  end

  # GET /users/1/checkins|todos
  # GET /users/1/checkins|todos/geo:1.23..-23.89/radius:10?limit=5&without_ids=1,5,3&max_user_set=3
  # GET /users/1/checkins|todos/city:chicago?limit=5&without_ids=1,5,3
  # GET /users/1/checkins|todos/all|friends|guys|gals|my|others
  def search
    # parse general parameters
    @max_user_set         = params[:max_user_set] ? params[:max_user_set].to_i : 5
    @without_ids          = params[:without_ids] ? params[:without_ids].split(',').map(&:to_i).uniq.sort : nil
    @grouped_user_ids     = Checkin.where(:id => @without_ids).select(:user_id).collect{ |o| o.user_id.to_i }.group_by(&:to_i) rescue {}
    # partition users into exclude, unweight lists based on checkin counts
    @unweight_user_ids    = Set.new
    @without_user_ids     = Set.new
    @grouped_user_ids.keys.each do |user_id|
      if @grouped_user_ids[user_id].size >= @max_user_set
        # exclude user
        @without_user_ids.add(user_id)
      else
        # unweight user
        @unweight_user_ids.add(user_id)
      end
    end
    @search   = params[:search] ? params[:search].to_s : 'all'
    @filter   = params[:checkins] # 'checkins', 'todos'
    @method   = "search_#{@search}_#{@filter}"
    @limit    = params[:limit] ? params[:limit].to_i : 100
    @options  = Hash[:without_user_ids => @without_user_ids.to_a.sort, :limit => @limit]
    @sort     = params.keys.select{ |k| k.to_s.match(/^sort/) }.map(&:to_sym)

    case @filter
    when 'checkins'
      @options.update(:without_checkin_ids => @without_ids)
      @order  = [:sort_closer_locations, :sort_checkins_past_week,
                 {:sort_unweight_users => @unweight_user_ids.to_a.sort}] + @sort
    when 'todos'
      @options.update(:without_todo_ids => @without_ids)
      @order  = [:sort_closer_locations, {:sort_unweight_users => @unweight_user_ids.to_a.sort}] + @sort
    end

    # add sort oder
    @options[:order] = @order

    case
    when params[:geo]
      @lat, @lng    = find_lat_lng
      @radius       = find_radius
      @options.update(:geo_origin => [@lat.radians, @lng.radians],
                      :geo_distance => 0.0..@radius.miles.meters.value)
    when params[:city]
      @city         = find_city
      @radius       = find_radius
      @options.update(:geo_origin => [@city.lat.radians, @city.lng.radians],
                      :geo_distance => 0.0..@radius.miles.meters.value)
    end

    # find objects
    @objects = @user.send(@method, @options)

    respond_to do |format|
      format.html
      format.js
      format.json do
        render :json => @objects.to_json
      end
    end
  end

  protected

  def find_user
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
  end

end