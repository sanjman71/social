class CheckinsController < ApplicationController
  before_filter :authenticate_user!, :only => [:index]
  before_filter :init_user, :only => [:index]
  skip_before_filter :check_beta, :only => :poll

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
    @checkin_logs  = CheckinLog.where("last_check_at < ?", Time.zone.now - Checkin.minimum_check_interval).group_by(&:user)

    @checkin_logs.each_pair do |user, logs|
      logs.each do |log|
        case log.source
        when 'facebook'
          FacebookCheckin.send_later(:import_checkins, user, Hash[:since => :last, :limit => 250])
        when 'foursquare'
          FoursquareCheckin.send_later(:import_checkins, user, Hash[:sinceid => :last, :limit => 250])
        end
      end
    end

    flash[:notice] = "Polling checkins for #{@checkin_logs.keys.size} users"
  end

  protected

  def init_user
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
  end

end