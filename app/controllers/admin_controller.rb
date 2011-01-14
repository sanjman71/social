class AdminController < ApplicationController
  before_filter :authenticate_user!

  privilege_required 'admin'

  # GET /admin
  def index
    
  end

  # GET /admin/checkins
  def checkins
    @dstart         = 3.months.ago.to_date
    @drange         = Range.new(@dstart, Date.today)
    # find member/non-member checkins per day
    @non_checkins   = Checkin.joins(:user).where(:checkin_at.gte => @dstart, :user => {:member => 0}).count(:group => "DATE(checkin_at)")
    @non_checkins   = @drange.map { |date| @non_checkins[date.to_s].to_i }
    @mem_checkins   = Checkin.joins(:user).where(:checkin_at.gte => @dstart, :user => {:member => 1}).count(:group => "DATE(checkin_at)")
    @mem_checkins   = @drange.map { |date| @mem_checkins[date.to_s].to_i }
    # find memeber checkins per day
    # @checkins   = @drange.map { |date| @checkins[date.to_s].to_i }
    # find male, female checkins per day
    @gal_checkins   = Checkin.joins(:user).where(:checkin_at.gte => @dstart, :user => {:gender => 1, :member => 1}).count(:group => "DATE(checkin_at)")
    @gal_checkins   = @drange.map { |date| @gal_checkins[date.to_s].to_i }
    @guy_checkins   = Checkin.joins(:user).where(:checkin_at.gte => @dstart, :user => {:gender => 2, :member => 1}).count(:group => "DATE(checkin_at)")
    @guy_checkins   = @drange.map { |date| @guy_checkins[date.to_s].to_i }
    # find planned checkins per day
    @todos          = PlannedCheckin.where(:planned_at.gte => @dstart).count(:group => "DATE(planned_at)")
    @todos          = @drange.map { |date| @todos[date.to_s].to_i }
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
    @mem_females      = User.member.where(:gender => 1).count
    @mem_males        = User.member.where(:gender => 2).count
    @non_females      = User.non_member.where(:gender => 1).count
    @non_males        = User.non_member.where(:gender => 2).count
  end

end