require 'digest/sha1'
require 'serialized_hash'
require 'thinking_sphinx/deltas/delayed_delta.rb'

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :lockable, :timeoutable and :activatable, :validatable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :omniauthable

  # Badges for authorization
  badges_authorized_user

  include Users::Follow
  include Users::Oauth
  include Users::Points
  include Users::Search

  validates_presence_of     :password,  :if => :password_required?
  validates_confirmation_of :password,  :if => :password_set?
  validates                 :handle, :presence => true, :unless => :rpx?

  has_many                  :email_addresses, :as => :emailable, :dependent => :destroy, :order => "priority asc",
                            :after_add => :after_add_email_address, :after_remove => :after_remove_email_address
  has_one                   :primary_email_address, :class_name => 'EmailAddress', :as => :emailable, :order => "priority asc"
  accepts_nested_attributes_for :email_addresses, :allow_destroy => true, :reject_if => :all_blank
  has_many                  :phone_numbers, :as => :callable, :dependent => :destroy, :order => "priority asc",
                            :after_add => :after_add_phone_number, :after_remove => :after_remove_phone_number
  has_one                   :primary_phone_number, :class_name => 'PhoneNumber', :as => :callable, :order => "priority asc"
  accepts_nested_attributes_for :phone_numbers, :allow_destroy => true, :reject_if => :all_blank

  belongs_to                :city
  accepts_nested_attributes_for :city, :allow_destroy => true, :reject_if => :all_blank

  # oauths
  has_many                  :oauths, :after_add => :event_oauth_added, :dependent => :destroy
  Oauth.providers.each do |s|
    has_one                 "#{s}_oauth".to_sym, :class_name => 'Oauth', :conditions => {:provider => s}
  end

  # checkins
  has_many                  :checkins, :after_add => :event_checkin_added, :dependent => :destroy
  # has_many                  :checkin_locations, :through => :checkins   # use locationships instead
  has_many                  :checkin_logs

  # planned checkins
  has_many                  :planned_checkins, :dependent => :destroy

  # shouts
  has_many                  :shouts, :dependent => :destroy

  # photos
  has_many                  :photos, :dependent => :destroy
  accepts_nested_attributes_for :photos, :allow_destroy => true, :reject_if => :all_blank
  has_one                   :primary_photo, :class_name => 'Photo', :order => 'photos.priority asc'
  Oauth.providers.each do |s|
    has_one                 "#{s}_photo", :class_name => 'Photo', :conditions => {:source => s}
  end

  has_many                  :user_suggestions, :dependent => :destroy
  has_many                  :suggestions, :through => :user_suggestions
  has_many                  :alerts, :dependent => :destroy
  has_many                  :badgings, :after_add => :event_badging_added, :dependent => :destroy
  has_many                  :badges, :through => :badgings
  has_many                  :badging_votes, :dependent => :destroy

  # friends
  has_many                  :friendships, :dependent => :destroy
  has_many                  :friends, :through => :friendships
  has_many                  :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id",
                            :dependent => :destroy
  has_many                  :inverse_friends, :through => :inverse_friendships, :source => :user

  # locationships
  has_many                  :locationships, :dependent => :destroy
  has_many                  :locations, :through => :locationships
  has_many                  :checkin_locations, :through => :locationships, :source => :location,
                            :conditions => ["my_checkins > 0"]
  has_many                  :todo_locations, :through => :locationships, :source => :location,
                            :conditions => ["todo_checkins > 0"]
  has_many                  :friend_locations, :through => :locationships, :source => :location,
                            :conditions => ["friend_checkins > 0"]
  has_many                  :checkin_todo_locations, :through => :locationships, :source => :location,
                            :conditions => ["my_checkins > 0 OR todo_checkins > 0"]

  # invitations
  has_many                  :invitations, :foreign_key => :sender_id, :dependent => :destroy

  # availability
  has_one                   :availability
  accepts_nested_attributes_for :availability, :allow_destroy => true

  # Preferences
  serialized_hash           :preferences,
                              {:import_checkin_emails => '0', :realtime_friend_checkin_emails => '0',
                               :follow_all_checkins_email => '1', :follow_nearby_checkins_email => '0'}

  before_save               :before_save_callback
  after_create              :manage_user_roles
  after_save                :event_user_saved
  before_save               :before_change_birthdate

  attr_accessor             :matchby, :matchvalue

  attr_accessible           :handle, :password, :password_confirmation, :remember_me, :gender, :orientation, :rpx,
                            :facebook_id, :city, :city_id, :member, :birthdate, :age,
                            :email_addresses_attributes, :phone_numbers_attributes, :photos_attributes,
                            :city_attributes, :availability_attributes, :tag_ids,
                            :preferences_import_checkin_emails,
                            :preferences_follow_all_checkins_email,
                            :preferences_follow_nearby_checkins_email

  # BEGIN acts_as_state_machine
  include AASM
  aasm_column               :state
  aasm_initial_state        :active
  aasm_state                :active
  aasm_state                :disabled

  aasm_event :disable do
    transitions :to => :disabled, :from => [:active]
  end

  aasm_event :activate do
    transitions :to => :active, :from => [:disabled]
  end
  # END acts_as_state_machine

  scope                     :member, where(:member => 1)
  scope                     :non_member, where(:member => 0)
  scope                     :with_oauths, joins(:oauths).where("oauths.id is not null").select("distinct users.id")
  scope                     :with_oauth, lambda { |s| joins(:oauths).where({:oauths => [:access_token => s]}) }
  scope                     :with_emails, where(:email_addresses_count.gt => 0)
  scope                     :no_emails, where(:email_addresses_count => 0)
  scope                     :with_email, lambda { |s| { :include => :email_addresses, :conditions => ["email_addresses.address = ?", s] } }
  scope                     :with_identifier, lambda { |s| { :include => :email_addresses, :conditions => ["email_addresses.identifier = ?", s] } }
  scope                     :with_phones, where(:phone_numbers_count.gt => 0)
  scope                     :no_phones, where(:phone_numbers_count => 0)
  scope                     :with_phone, lambda { |s| { :include => :phone_numbers, :conditions => ["phone_numbers.address = ?", s] } }

  scope                     :search_by_name, lambda { |s| { :conditions => ["LOWER(users.name) REGEXP '%s'", s.downcase] }}
  scope                     :order_by_name, order('users.name asc')

  scope                     :search_by_name_email_phone, lambda { |s| {
                                                                  :include => [:email_addresses, :phone_numbers],
                                                                  :conditions => ["LOWER(users.name) LIKE ? OR LOWER(email_addresses.address) LIKE ? OR phone_numbers.address LIKE ?", '%' + s.downcase + '%', '%' + s.downcase + '%', '%' + s.downcase + '%']
                                                                  }}


  # define_index do
  #   has :id, :as => :user_ids
  #   indexes handle, :as => :handle
  #   has gender, :as => :gender
  #   has member, :as => :member
  #   has availability.now, :as => :now
  #   has tag_ids, :as => :tag_ids, :type => :multi
  #   has friend_set_ids, :as => :friend_ids, :type => :multi
  #   # checkins
  #   has checkins(:id), :as => :checkin_ids
  #   has checkins_count, :as => :checkins_count
  #   # locationships
  #   has locations(:id), :as => :location_ids
  #   # checkin location tags
  #   # indexes locations.tags(:name), :as => :tags
  #   # has locations.tags(:id), :as => :tag_ids
  #   # convert degrees to radians for sphinx
  #   has 'RADIANS(users.lat)', :as => :lat,  :type => :float
  #   has 'RADIANS(users.lng)', :as => :lng,  :type => :float
  #   # use delayed job for delta index
  #   set_property :delta => :delayed
  #   # only index active users
  #   where "state = 'active'"
  # end
  
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.  
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(email_or_phone, password, options={})
    return nil if email_or_phone.blank?
    if PhoneNumber.phone?(email_or_phone)
      # phone authentication
      users = self.with_phone(PhoneNumber.format(email_or_phone)).find_in_states(:all, [:active, :data_missing])# need to get the salt
    else
      # assume email authentication
      users = self.with_email(email_or_phone).find_in_states(:all, [:active, :data_missing]) # need to get the salt
    end
    # authentication fails if there is no user or more than 1 user
    return nil if users.empty? or users.size > 1
    u = users.first
    # check is user password is blank
    return u if u.encrypted_password.blank? and u.password.blank? and password.blank?
    # authenticate
    u.authenticated?(password) ? u : nil
  end

  # devise authenticate method
  def self.find_for_database_authentication(conditions)
    value = conditions[authentication_keys.first]
    conditions = ["handle = ? or email = ?", value, value]
    find(:first, conditions)
  end

  def self.find_by_email_or_phone(email, phone)
    users = self.with_email(email)
    users = self.with_phone(phone) if users.empty?
    users 
  end

  def self.find_by_oauth_token(s)
    User.with_oauth(s).first
  end

  # find users in the specified states
  def self.find_in_states(number, states)
    self.find(number, :conditions => ["users.state IN (?)", states.map(&:to_s)])
  end

  def self.create_rpx(name, email, identifier, options={})
    User.transaction do
      # create user in passive state
      user = self.create({:name => name, :rpx => 1}.update(options))
      # rpx users don't always have emails
      unless email.blank?
        # add email address with rpx identifier
        email = user.email_addresses.create(:address => email, :identifier => identifier)
        # change email state to verfied
        email.verify!
      end
      user
    end
  end
  
  def self.generate_password(length=6)
    chars    = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNOPQRSTUVWXYZ23456789'
    password = ''
    length.times { |i| password << chars[rand(chars.length)] }
    password
  end

  def self.valid_facebook_handle?(s)
    s.blank? ? false : s.match(/^\w+$/)
  end

  def self.regex_email
    /^[a-zA-Z0-9\+._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/
  end

  # the special user 'anyone'
  def self.anyone(name = 'Anyone')
    r = User.new do |o|
      o.name = name
      o.send(:id=, 0)
    end
  end

  # find common friends among specified users
  def self.common_friends(user1, user2)
    common_ids = (user1.friend_set & user2.friend_set).sort
    User.find(common_ids) rescue []
  end

  # override default nested attributes method
  def city_attributes=(attrs)
    case
    when attrs[:id].present?
      # find city by id or create new one
      city = City.find_by_id(attrs[:id]) || Locality.resolve(attrs[:name], :precision => city, :create => true)
    when attrs[:name].present?
      # find existing city or create new one
      city = Locality.resolve(attrs[:name], :precision => city, :create => true)
    end
    self.city = city
  rescue Exception => e
    # ignore invalid city
  end

  # return true if its the special user 'anyone'
  def anyone?
    self.id == 0
  end

  # find user's facebook oauth; allow use of friend's oauth if :friend => true
  def find_facebook_oauth(options={})
    oauth = oauths.facebook.first
    if oauth.blank? and options[:friend]
      # use a member friend's oauth token
      oauth = (friends.member + inverse_friends.member).first.oauths.facebook.first rescue nil
    end
    oauth
  end

  # handle gender as string, e.g. 'female', 'male'
  def gender=(s)
    if s.is_a?(String)
      case
      when s.downcase.match(/^female$/)
        s = 1
      when s.downcase.match(/^male$/)
        s = 2
      else
        s = 0
      end
    end
    write_attribute(:gender, s)
  end

  def gender?
    self.gender != 0
  end

  def female?
    self.gender == 1
  end

  def male?
    self.gender == 2
  end

  def gender_name
    case self.gender
    when 1
      'female'
    when 2
      'male'
    else
      ''
    end
  end

  def pronoun
    male? ? 'him' : 'her'
  end

  alias :him_her :pronoun

  def he_she
    male? ? 'he' : 'she'
  end

  def possessive_pronoun
    male? ? 'his' : 'her'
  end

  alias :his_her :possessive_pronoun

  # handle orientation as string, e.g. 'bisexual, 'gay', 'straight'
  def orientation=(s)
    if s.is_a?(String)
      case
      when s.downcase.match(/^bisexual$/)
        s = 1
      when s.downcase.match(/^gay$/)
        s = 2
      when s.downcase.match(/^straight$/)
        s = 3
      else
        s = 3 # default
      end
    end
    write_attribute(:orientation, s)
  end

  def orientation_name
    case self.orientation
    when 1
      'bisexual'
    when 2
      'gay'
    when 3
      'straight'
    else
      ''
    end
  end

  def tag_ids
    read_attribute(:tag_ids).present? ? read_attribute(:tag_ids).split(',').map(&:to_i) : []
  end

  def tag_ids=(o)
    case
    when o.blank?
      write_attribute(:tag_ids, nil)
    when o.is_a?(Array)
      write_attribute(:tag_ids, o.uniq.sort.join(','))
    when o.is_a?(String)
      if o.match(/^\d+(,\d+){0,}$/)
        write_attribute(:tag_ids, o)
      end
    end
  rescue Exception => e
    write_attribute(:tag_ids, nil)
  end

  # map friend_set_ids string to a collection
  def friend_set
    (self.friend_set_ids || '').split(',').map(&:to_i)
  end

  def rpx?
    self.rpx == 1
  end

  # returns true iff the user has a latitude and longitude
  def mappable?
    (self.lat and self.lng) ? true : false
  end

  # try in priority order
  def primary_photo_url
    primary_photo.try(:url) || facebook_photo_url || Photo.send("default_#{gender_name}") rescue nil || default_photo_url
  end

  def facebook_photo_url
    facebook_id ? "https://graph.facebook.com/#{facebook_id}/picture?type=square" : nil
  end

  def default_photo_url
    Photo.default_asexual
  end

  def badges_list
    badges.collect(&:name)
  end

  # def profile_complete?
  #   return false if (self.reload.email_missing? or self.reload.phone_missing?)
  #   true
  # end

  # return true if a email address is required but user doesn't have one
  def email_missing?
    case self.preferences[:email]
    when 'optional'
      false
    when 'required'
      self.email_addresses_count == 0
    else
      false
    end
  end

  # address of primary email address
  def email_address
    @email_address ||= self.email_addresses_count > 0 ? self.primary_email_address.address : ''
  end

  # return true if a phone number is required but user doesn't have one
  def phone_missing?
    case self.preferences[:phone]
    when 'optional'
      false
    when 'required'
      self.phone_numbers_count == 0
    else
      false
    end
  end

  # address of primary phone number
  def phone_number
    @phone_number ||= self.phone_numbers_count > 0 ? self.primary_phone_number.address : ''
  end

  def password?
    !self.encrypted_password.blank?
  end

  def last_checkin_after(timestamp)
    checkins.where(:checkin_at.gt => timestamp).order("checkin_at desc").limit(1).first
  end

  # find user's most recent checkin_at in the specified format
  # format:
  # :facebook => '20081031T120000'
  # :foursquare => 1302094191
  def last_checkin_at(format, default=nil)
    checkin = checkins.order("checkin_at desc").limit(1).first
    begin
      case format
      when :facebook
        checkin.checkin_at.utc.to_s(:datetime_schedule)
      when :foursquare
        checkin.checkin_at.utc.to_i
      end
    rescue
      default
    end
  end

  #
  # learn methods
  #
  
  def learns_add(user)
    @redis  = RedisSocket.new
    @key    = "user:#{self.id}:learn"
    @value  = "user:#{user.id}"
    @redis.sadd(@key, @value)
  end

  def learns_remove(user)
    @redis  = RedisSocket.new
    @key    = "user:#{self.id}:learn"
    @value  = "user:#{user.id}"
    @redis.srem(@key, @value)
  end

  def learns_get
    @redis  = RedisSocket.new
    @key    = "user:#{self.id}:learn"
    @redis.smembers(@key)
  end

  # returns true if the user is ready to receive suggestions
  def suggestionable?
    self.checkins_count >= Checkin.min_checkins_for_suggestion
  end

  # add user badges based on checkin location tags
  # called by badge worker
  def async_add_badges
    tag_ids       = checkins.joins(:location).includes(:location => :tags).collect{|o| o.location.tags}.flatten.collect(&:id).uniq
    # tag_ids       = checkins.includes(:location).collect(&:location).collect(&:tags).flatten.collect(&:id).uniq
    # tag_ids       = checkin_locations.collect(&:tags).flatten.collect(&:id).uniq
    return [] if tag_ids.blank?
    match_badges  = Badge.search(tag_ids)
    # find new badges
    new_badges    = match_badges - badges
    new_badges.each do |badge|
      # add new badge
      badgings.create(:badge => badge)
    end
    new_badges
  end

  # called after a location is tagged asynchronously
  # called by location worker
  def event_location_tagged(location, force=false)
    # check that location is a checkin or todo location
    if !force and !locationships.my_todo_or_checkin.select(:location_id).collect(&:location_id).include?(location.try(:id))
      return false
    end

    add_ids = location.tag_ids
    if (add_ids - tag_ids).any?
      # add the new tag ids
      self.tag_ids = add_ids + tag_ids
      save
    else
      false
    end
  end

  def send_planned_checkin_reminders
    # check if user has an email address
    return 0 if email_addresses_count == 0
    # look for planned checkins that expire in 2-3 days, without a reminder_at timestamp
    pcheckins = planned_checkins.active.where(:expires_at.gt => 2.days.from_now, :expires_at.lt => 3.days.from_now,
                                              :reminder_at => nil)
    pcheckins.each do |pcheckin|
      # send email
      Resque.enqueue(CheckinMailerWorker, :todo_reminder, 'todo_id' => pcheckin.id, 'points' => Currency.for_completed_todo)
      # set reminder_at timestamp
      pcheckin.update_attribute(:reminder_at, Time.zone.now)
    end
    pcheckins.size
  end

  def send_alert(options)
    case options[:id]
    # deprecated
    # when :linked_account
    #   options.update(:level => 'notice', :subject => 'checkins', :message => I18n.t('alert.linked_account'))
    when :need_bucks
      options.update(:level => 'notice', :subject => 'bucks', :message => I18n.t('alert.need_bucks'))
    end

    User.transaction do
      # find any existing alerts with same subject
      objects = self.alerts.where("alerts.subject = ?", options[:subject])

      if objects
        # remove old alerts
        objects.each { |o| o.destroy }
      end

      # create alert
      self.alerts.create(options)
    end
  end

  def tableize
    self.class.to_s.tableize
  end

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

  protected

  # password is not required
  def password_required?
    return false
  end

  def password_set?
    !self.password.blank?
  end

  def make_activation_code
    self.deleted_at = nil
    self.activation_code = self.class.make_token
  end

  def before_save_callback
    if self.lat.blank? and self.lng.blank? and self.city
      self.lat = self.city.lat
      self.lng = self.city.lng
    end
    if self.radius.to_i == 0
      self.radius = 50
    end
  end

  def manage_user_roles
    unless self.has_role?('user manager', self)
      # all users can manage themselves
      self.grant_role('user manager', self)
    end
  end

  def after_add_email_address(email_address)
    return if email_address.new_record?
  end

  def after_remove_email_address(email_address)
    return if email_address.new_record?
  end

  def after_add_phone_number(phone_number)
    return if phone_number.new_record?
  end

  def after_remove_phone_number(phone_number)
    return if phone_number.new_record?
  end

  def before_change_birthdate
    if changes[:birthdate]
      # update age
      self.age = (Date.today - birthdate).to_i/365.242199.to_i rescue 0
    end
  end

  def event_user_saved
    # delegate to other callbacks
    after_change_points
    after_member_signup
    after_invite_token_assigned
  end

  # after_save callback to handle point changes
  def after_change_points
    if changes[:points] and changes[:points][0] > 0 and changes[:points][1] <= 0
      # points went from positive to negative
      send_alert(:id => :need_bucks)
    end
  end

  # send email after member signup
  def after_member_signup
    if changes[:member] and changes[:member][1] == true
      self.class.log("[user:#{id}] #{handle} member signup")
      # send email to all users who poked a friend to invite user
      pokes = InvitePoke.where(:invitee_id => self.id)
      pokes.each do |poke|
        Resque.enqueue(UserMailerWorker, :user_signup_to_poker, 'poke_id' => poke.id)
      end
      Resque.enqueue(UserWorker, :member_signup, 'user_id' => id)
      # send email to admins user re: new member signup
      Resque.enqueue(UserMailerWorker, :user_signup, 'user_id' => id)
    end
  end

  # send email to inviter when an invitee signs up
  def after_invite_token_assigned
    if changes[:invitation_token] and changes[:invitation_token][1].present?
      invite  = Invitation.find_by_token(invitation_token)
      inviter = invite.try(:sender)
      self.class.log("[user:#{id}] #{handle} signup using invite from user:#{inviter.try(:id)}:#{inviter.try(:handle)} with token:#{invitation_token}")
      # invitee gets email that invitee signed up
      Resque.enqueue(UserMailerWorker, :user_invite_accepted, 'user_id' => self.id)
      # invitee auto follows inviter
      self.follow(inviter)
    end
  end

  # checkin added
  def event_checkin_added(checkin)
    # add points for checkin
    add_points(Currency.points_for_checkin(self, checkin))
  end

  # badging added
  def event_badging_added(badging)
    if member? and email_addresses_count?
      Resque.enqueue(UserMailerWorker, :user_badge_added, 'badging_id' => badging.id)
    end
  end

  # oauth added
  def event_oauth_added(oauth)
    if !member
      # make user a member
      update_attribute(:member, true)
      update_attribute(:member_at, Time.zone.now)
    end
  end

end
