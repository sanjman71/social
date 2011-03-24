class AdminController < ApplicationController
  before_filter :authenticate_user!
  layout        'admin'

  privilege_required 'admin'

  # GET /admin
  def index
    
  end

  # GET /admin/checkins_chart
  def checkins_chart
    @dstart             = 3.months.ago.to_date
    @drange             = Range.new(@dstart, Date.today)
    # find member/non-member checkins per day
    @non_checkins       = Checkin.joins(:user).where(:checkin_at.gte => @dstart, :user => {:member => 0}).count(:group => "DATE(checkin_at)")
    @non_checkins       = @drange.map { |date| @non_checkins[date.to_s].to_i }
    @mem_checkins       = Checkin.joins(:user).where(:checkin_at.gte => @dstart, :user => {:member => 1}).count(:group => "DATE(checkin_at)")
    @mem_checkins       = @drange.map { |date| @mem_checkins[date.to_s].to_i }
    # find memeber checkins per day
    # @checkins   = @drange.map { |date| @checkins[date.to_s].to_i }
    # find member/non-member male/female checkins per day
    @mem_gal_checkins   = Checkin.joins(:user).where(:checkin_at.gte => @dstart, :user => {:gender => 1, :member => 1}).count(:group => "DATE(checkin_at)")
    @mem_gal_checkins   = @drange.map { |date| @mem_gal_checkins[date.to_s].to_i }
    @mem_guy_checkins   = Checkin.joins(:user).where(:checkin_at.gte => @dstart, :user => {:gender => 2, :member => 1}).count(:group => "DATE(checkin_at)")
    @mem_guy_checkins   = @drange.map { |date| @mem_guy_checkins[date.to_s].to_i }

    @non_gal_checkins   = Checkin.joins(:user).where(:checkin_at.gte => @dstart, :user => {:gender => 1, :member => 0}).count(:group => "DATE(checkin_at)")
    @non_gal_checkins   = @drange.map { |date| @non_gal_checkins[date.to_s].to_i }
    @non_guy_checkins   = Checkin.joins(:user).where(:checkin_at.gte => @dstart, :user => {:gender => 2, :member => 0}).count(:group => "DATE(checkin_at)")
    @non_guy_checkins   = @drange.map { |date| @non_guy_checkins[date.to_s].to_i }

    # find planned checkins per day
    @todos              = PlannedCheckin.where(:planned_at.gte => @dstart).count(:group => "DATE(planned_at)")
    @todos              = @drange.map { |date| @todos[date.to_s].to_i }
  end

  # GET /admin/invites_chart
  def invites_chart
    @data     = Invitation.count(:group => "DATE(sent_at)", :order => "sent_at asc")
    # parse first date, convert to msec
    @dtime1   = DateTime.parse(@data.first[0]).to_i * 1000
    # build array of objects per day
    @invites  = @data.map{ |date, count| count }
  end

  # GET /admin/tags_chart
  def tags_chart
    # tag histogram
    @tag_histogram  = Location.tag_counts_on(:tags).order("count desc").limit(@limit || 20)
    @tag_names      = @tag_histogram.collect(&:name)
    @tag_counts     = @tag_histogram.collect(&:count)
    @badge_counts   = @tag_histogram.collect{ |tag| Badge.search(tag.id).size }
  end

  # GET /admin/users_chart
  def users_chart
    @mem_females    = User.member.where(:gender => 1).count
    @mem_males      = User.member.where(:gender => 2).count
    @non_females    = User.non_member.where(:gender => 1).count
    @non_males      = User.non_member.where(:gender => 2).count
  end

  # GET /admin/user_emails
  def user_emails
    # find all member email addresses
    @emails         = User.member.includes(:email_addresses).collect{ |o| o.primary_email_address.try(:address) }.compact
  end

  # GET /admin/emails_chart
  def emails_chart
    @redis      = RedisSocket.new
    @redis_keys = @redis.keys("2011*emails").sort

    # parse first date, e.g. "20110201"
    @dstart     = Date.parse(@redis_keys.first.match(/(\d+):emails/)[1]) rescue Date.today
    @drange     = Range.new(@dstart, Date.today)

    @email_keys = ['friend_realtime_checkin', 'imported_checkin', 'invite', 'message', 'share_drink']
    @email_hash = {}

    @drange.each do |date|
      # convert date format "2011-02-01" to "20110201"
      date = date.to_s.gsub("-",'')
      # get hash for the date
      hash = @redis.hgetall("#{date}:emails")
      Rails.logger.debug("hash: #{hash.inspect}")
      @email_keys.each do |key|
        @email_hash[key] ||= []
        @email_hash[key].push(hash[key].to_i)
      end
    end
  end
end