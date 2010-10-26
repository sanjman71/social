class CheckinsController < ApplicationController
  before_filter       :authenticate_user!, :only => [:index]
  before_filter       :init_user, :only => [:index]
  skip_before_filter  :check_beta, :only => :poll
  respond_to          :html, :json

  # GET /checkins
  def index
    # group checkins by source
    @checkins     = @user.checkins.group_by(&:source_type)
    @checkin_logs = @user.checkin_logs.inject(Hash[]) do |hash, log|
      mm, ss = (Time.zone.now-log.last_check_at).divmod(60)
      # track minutes ago
      hash[log.source] = mm
      hash
    end
  end

  # GET /poll
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

  # GET /checkins/facebook/9999/count
  # GET /checkins/foursquare/9999/count
  def count
    @source     = params[:source]
    @source_id  = params[:source_id]
    @user       = current_user
    @oauth      = Oauth.find_user_oauth(@user, @source)

    begin
      case @source
      when 'facebook'
        @facebook = FacebookClient.new(@oauth.access_token)
        @since    = Time.zone.now.beginning_of_year.to_s(:datetime_schedule)
        @limit    = 25
        @options  = Hash[:since => @since, :limit => @limit]
        @checkins = @facebook.checkins(@source_id, @options)['data']
        @status   = 'ok'
      end
    rescue Exception => e
      @checkins = []
      @status   = 'error'
      @message  = e.message
    end

    respond_with(@checkins) do |format|
      format.json { render :json => Hash[:status => @status, :count => @checkins.size, :message => @message]}
    end
  end

  protected

  def init_user
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
  end

end