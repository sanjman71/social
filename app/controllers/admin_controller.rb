class AdminController < ApplicationController
  before_filter :authenticate_user!

  privilege_required 'admin'

  # GET /admin
  def index
    
  end

  # GET /admin/checkins
  def checkins
    @dstart     = 1.month.ago.to_date
    @drange     = Range.new(@dstart, Date.today)
    # find checkins per day
    @checkins   = Checkin.where(:checkin_at.gte => @dstart).count(:group => "DATE(checkin_at)")
    @checkins   = @drange.map { |date| @checkins[date.to_s].to_i }
    # find planned checkins per day
    @todos      = PlannedCheckin.where(:planned_at.gte => @dstart).count(:group => "DATE(planned_at)")
    @todos      = @drange.map { |date| @todos[date.to_s].to_i }
  end

  # GET /admin/invites
  def invites
    @data     = Invitation.count(:group => "DATE(sent_at)", :order => "sent_at asc")
    # parse first date, convert to msec
    @dtime1   = DateTime.parse(@data.first[0]).to_i * 1000
    # build array of objects per day
    @invites  = @data.map{ |date, count| count }
  end

  # GET /admin/users
  def users
    # @members          = User.member.count
    @mem_females      = User.member.where(:gender => 1).count
    @mem_males        = User.member.where(:gender => 2).count
    # @non_members      = User.non_member.count
    @non_females      = User.non_member.where(:gender => 1).count
    @non_males        = User.non_member.where(:gender => 2).count
  end

end