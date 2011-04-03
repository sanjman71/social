class CheckinsController < ApplicationController
  before_filter       :authenticate_user!, :only => [:whatnow, :index, :search]
  before_filter       :find_checkin, :only => [:whatnow]
  before_filter       :find_user, :only => [:search]
  respond_to          :html, :json, :js

  privilege_required  'admin', :only => [:index]

  def page_size
    20
  end

  # GET /checkins
  # GET /admin/checkins
  # GET /admin/checkins?limit=10&page=0&member=1
  def index
    @page       = params[:page] ? params[:page].to_i : 1
    @limit      = params[:limit] ? params[:limit].to_i : page_size

    @search     = Checkin.search(params[:search])

    if @search.search_attributes.values.any?(&:present?)
      @checkins = @search.order("checkin_at asc").page(@page).per(@limit)
    else
      @checkins = @search.order("checkin_at desc").page(@page).per(@limit)
    end

    respond_to do |format|
      format.html { render(:action => 'index', :layout => 'admin') }
    end
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

  # GET /checkins/1/whatnow
  def whatnow
    # @checkin initalized in before filter

    @user       = @checkin.user
    @location   = @checkin.location

    @todos      = current_user.planned_checkins.active
  end

  protected

  def find_checkin
    @checkin = Checkin.find(params[:id])
  end

  def find_user
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
  end

end