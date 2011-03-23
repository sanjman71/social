require File.expand_path('config/environment.rb')

class Checkins < Thor

  desc "list", "list recent checkins across all users"
  method_options :limit => 100
  def list
    limit     = options[:limit].to_i
    puts "#{Time.now}: listing #{limit} recent checkins"
    checkins  = Checkin.limit(limit).order("checkin_at desc")

    checkins.each do |checkin|
      puts "checkin: at #{checkin.location.name}:#{checkin.location.city.try(:name)}, by #{checkin.user.handle}:#{checkin.user.id}"
    end
  end

  desc "matches", "find checkin matches for user --handle"
  method_options :handle => nil
  method_options :limit => 100
  def matches
    handle  = options[:handle]
    limit   = options[:limit].to_i

    if handle.blank?
      puts "missing handle"
      return
    end

    user      = User.find_by_handle!(handle)
    checkins  = user.checkins.limit(limit).order("checkin_at desc")

    puts "*** user: #{user.handle} checkin matches"
    checkins.each do |checkin|
      puts "*** checkin: at #{checkin.location.name}:#{checkin.location.city.try(:name)}, by #{checkin.user.handle}:#{checkin.user.id}"
      matches = checkin.match_strategies([:exact, :similar, :nearby], :limit => 3)
      if matches.blank?
        puts "xxx no matches"
      end
      matches.each do |match|
        puts "*** match: at #{match.location.name}:#{match.location.city.try(:name)}, by #{match.user.handle}:#{match.user.id}"
      end
    end
  end

  desc "near_handle", "search checkins around --handle, with optional --sort options: females, males"
  method_options :handle => nil
  method_options :sort => nil
  method_options :radius => nil
  def near_handle
    handle  = options[:handle]
    radius  = options[:radius] ? options[:radius].to_i : 100

    if handle.blank?
      puts "missing handle"
      return
    end

    user      = User.find_by_handle!(handle)
    city      = user.city
    puts "*** searching #{radius} miles around #{city.try(:name)}"
    params    = {:geo_origin => [city.lat.try(:radians), city.lng.try(:radians)],
                 :geo_distance => 0.0..radius.miles.meters.value}
    if options[:sort]
      # add sort options
      params.merge!(:order => [:sort_females]) if options[:sort] == 'females'
      params.merge!(:order => [:sort_males]) if options[:sort] == 'males'
    end
    puts "*** params: #{params.inspect}"
    checkins  = user.search_all_checkins(params)

    checkins.each do |checkin|
      puts "[checkin] at #{checkin.location.name}:#{checkin.location.city.try(:name)}, by #{checkin.user.handle}:#{checkin.user.gender_name}"
    end
  end
  
  desc "poll", "poll for recent user checkins"
  def poll
    puts "#{Time.now}: polling user checkins"
    users = Checkin.event_poll_checkins
    puts "#{Time.now}: triggered polling for #{users.size} users"
  end

  desc "send_planned_checkin_reminders", "send planned checkin reminders"
  def send_planned_checkin_reminders
    puts "#{Time.now}: checking planned checkins that are expiring soon"
    users = PlannedCheckin.select("distinct user_id, planned_checkins.*").collect(&:user)
    users.each do |user|
      count = user.send_planned_checkin_reminders
      if count > 0
        puts "#{Time.now}: [user:#{user.id}] #{user.handle} sending #{count} planned checkin reminder"
      end
    end
    puts "#{Time.now}: completed"
  end

  desc "expire_planned_checkins", "check for expired planned checkins"
  def expire_planned_checkins
    puts "#{Time.now}: expiring planned checkins"
    expired = PlannedCheckin.expire_all
    puts "#{Time.now}: expired #{expired} planned checkins"
  end

  desc "send_realtime", "send realtime checkins to members who are 'out'"
  def send_realtime
    puts "#{Time.now}: sending realtime checkins ..."
    Resque.enqueue(CheckinWorker, :search_realtime_checkin_matches)
    puts "#{Time.now}: queued job"
  end

  desc "send_daily", "send daily checkins to members"
  def send_daily
    puts "#{Time.now}: sending daily checkins ..."
    Resque.enqueue(CheckinWorker, :search_daily_checkin_matches)
    puts "#{Time.now}: queued job"
  end

  desc "stats", "checkin stats spanning number of days, weeks"
  method_options :sendto => nil
  method_options :filename => nil
  def stats
    require 'csv'
    puts "#{Time.now}: building queries ..."
    sendto    = options[:sendto].split(',') rescue []
    filename  = options[:filename]

    # find total users, member users, non-oath users
    total_users   = User.count
    member_users  = User.member.count
    other_users   = total_users - member_users

    # build daily checkins data
    checkins      = {}
    1.upto(6) do |i|
      checkins_count = Checkin.where(:checkin_at.gt => eval("#{i}.days.ago"), :checkin_at.lt => eval("#{i-1}.days.ago")).count
      checkins[i] = checkins_count
    end

    # build weekly checkin data
    [7, 14, 21, 28].each do |i|
      checkins_count = Checkin.where(:checkin_at.gt => eval("#{i}.days.ago"), :checkin_at.lt => eval("#{i-7}.days.ago")).count
      checkins[i] = checkins_count
    end

    data = CSV.generate(:col_sep => ',') do |csv|
      csv << ['total users', 'members', 'others',
              'checkins 1 day ago', 'checkins 2 days ago', 'checkins 3 days ago', 'checkins 4 days ago',
              'checkins 5 days ago', 'checkins 6 days ago',
              'checkins last week', 'checkins 2 weeks ago', 'checkins 3 weeks ago', 'checkins 4 weeks ago']
      csv << [total_users, member_users, other_users,
              checkins[1], checkins[2], checkins[3], checkins[4], checkins[5], checkins[6],
              checkins[7], checkins[14], checkins[21], checkins[28]
             ]
    end

    # puts data.inspect

    filename ||= "basic_user_checkins.#{Time.zone.now.to_s(:datetime_compact)}.csv"
    file = File.open(filename, 'w')
    file.write(data)
    file.close

    if sendto.any?
      puts "#{Time.now}: sending to: #{sendto.inspect}, file: #{filename}"
      CheckinMailer.checkin_stats(:emails => sendto, :file => filename).deliver
    end
  end
end
