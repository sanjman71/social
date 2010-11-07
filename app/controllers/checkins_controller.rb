class CheckinsController < ApplicationController
  before_filter       :authenticate_user!, :only => [:index]
  before_filter       :find_user, :only => [:index]
  skip_before_filter  :check_beta, :only => :poll
  respond_to          :html, :json, :js

  # GET /users/1/checkins
  # GET /users/1/checkins/geo:1.23..-23.89/radius:10?limit=5&without_checkin_ids=1,5,3
  # GET /users/1/checkins/city:chicago?limit=5&without_checkin_ids=1,5,3
  # GET /users/1/checkins/all|friends|my|other
  def index
    # parse general parameters
    @without_checkin_ids  = params[:without_checkin_ids] ? params[:without_checkin_ids].split(',').map(&:to_i).uniq.sort : nil
    @search               = params[:search] ? params[:search].to_s : 'all'
    @method               = "search_#{@search}_checkins"
    @order                = params[:order].to_s == 'all' ? [:sort_similar_checkins, :sort_other_checkins] : nil
    @limit                = params[:limit] ? params[:limit].to_i : 2**30
    @options              = Hash[:without_checkin_ids => @without_checkin_ids,
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

  # GET /checkins/poll
  def poll
    # find checkin_logs that need to be polled
    @checkin_logs  = CheckinLog.where("last_check_at < ?", Time.zone.now - Checkin.poll_interval).group_by(&:user)

    @checkin_logs.each_pair do |user, logs|
      logs.each do |log|
        case log.source
        when 'facebook'
          FacebookCheckin.delay.async_import_checkins(user, Hash[:since => :last, :limit => 250])
        when 'foursquare'
          FoursquareCheckin.delay.async_import_checkins(user, Hash[:sinceid => :last, :limit => 250])
        end
      end
    end

    flash[:notice] = "Polling checkins for #{@checkin_logs.keys.size} users"
  end

  protected

  def find_user
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
  end

end