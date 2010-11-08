require 'digest/sha1'
require 'serialized_hash'
require 'thinking_sphinx/deltas/delayed_delta.rb'

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :lockable, :timeoutable and :activatable, :validatable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :oauthable

  # Badges for authorization
  badges_authorized_user

  include Users::Oauth
  include Users::Points
  include Users::Search

  validates_presence_of     :password,  :if => :password_required?
  validates_confirmation_of :password,  :if => :password_set?
  validates                 :handle, :presence => true, :uniqueness => true, :unless => :rpx?

  has_many                  :email_addresses, :as => :emailable, :dependent => :destroy, :order => "priority asc",
                            :after_add => :after_add_email_address, :after_remove => :after_remove_email_address
  has_one                   :primary_email_address, :class_name => 'EmailAddress', :as => :emailable, :order => "priority asc"
  accepts_nested_attributes_for :email_addresses, :allow_destroy => true, :reject_if => :all_blank
  has_many                  :phone_numbers, :as => :callable, :dependent => :destroy, :order => "priority asc",
                            :after_add => :after_add_phone_number, :after_remove => :after_remove_phone_number
  has_one                   :primary_phone_number, :class_name => 'PhoneNumber', :as => :callable, :order => "priority asc"
  accepts_nested_attributes_for :phone_numbers, :allow_destroy => true, :reject_if => :all_blank

  belongs_to                :city

  # oauths
  has_many                  :oauths
  Oauth.providers.each do |s|
    has_one                 "#{s}_oauth".to_sym, :class_name => 'Oauth', :conditions => {:provider => s}
  end

  # checkins
  has_many                  :checkins, :after_add => :after_add_checkin
  has_many                  :checkin_locations, :through => :checkins
  has_many                  :checkin_logs

  # photos
  has_many                  :photos
  accepts_nested_attributes_for :photos, :allow_destroy => true, :reject_if => :all_blank
  has_one                   :primary_photo, :class_name => 'Photo', :order => 'photos.priority asc'
  Oauth.providers.each do |s|
    has_one                 "#{s}_photo", :class_name => 'Photo', :conditions => {:source => s}
  end

  has_many                  :user_suggestions
  has_many                  :suggestions, :through => :user_suggestions
  has_many                  :alerts
  has_many                  :badgings
  has_many                  :badges, :through => :badgings
  has_many                  :badging_votes

  # friends
  has_many                  :friendships
  has_many                  :friends, :through => :friendships
  has_many                  :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id"
  has_many                  :inverse_friends, :through => :inverse_friendships, :source => :user

  # locationships
  has_many                  :locationships
  has_many                  :locations, :through => :locationships
  has_many                  :checkin_locations, :through => :locationships, :source => :location,
                            :conditions => ["my_checkins > 0"]
  has_many                  :planned_locations, :through => :locationships, :source => :location,
                            :conditions => ["planned_checkins > 0"]

  # Preferences
  serialized_hash           :preferences, {:provider_email_text => '', :provider_email_daily_schedule => '0',
                                           :phone => 'optional', :email => 'optional'}

  before_save               :before_save_callback
  # after_create              :manage_user_roles
  after_create              :send_signup_email
  after_save                :after_add_facebook_id

  attr_accessor             :matchby, :matchvalue

  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible           :handle, :password, :password_confirmation, :gender, :rpx, :facebook_id, :city, :city_id,
                            :email_addresses_attributes, :phone_numbers_attributes, :photos_attributes,
                            :preferences_phone, :preferences_email

  # BEGIN acts_as_state_machine
  include AASM
  aasm_column               :state
  aasm_initial_state        :active
  aasm_state                :active
  # END acts_as_state_machine

  scope                     :with_oauths, joins(:oauths).where("oauths.id is not null").select("distinct users.id")
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


  define_index do
    has :id, :as => :user_ids
    indexes handle, :as => :handle
    has :gender, :as => :gender
    # checkin locations
    has locations(:id), :as => :location_ids, :facet => true
    indexes locations.tags(:name), :as => :tags
    has locations.tags(:id), :as => :tag_ids, :facet => true
    has checkins(:id), :as => :checkin_ids, :facet => true
    has :checkins_count, :as => :checkins_count
    # convert degrees to radians for sphinx
    has 'RADIANS(users.lat)', :as => :lat,  :type => :float
    has 'RADIANS(users.lng)', :as => :lng,  :type => :float
    # real time indexing with delayed_job
    # set_property :delta => :delayed
    # only index active users
    where "state = 'active'"
  end
  
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

  # the special user 'anyone'
  def self.anyone(name = 'Anyone')
    r = User.new do |o|
      o.name = name
      o.send(:id=, 0)
    end
  end

  # return true if its the special user 'anyone'
  def anyone?
    self.id == 0
  end

  # set gender when its specified as a string
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

  def singular_object
    male? ? 'him' : 'her'
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

  # return true if the user was created in the past few minutes
  def created_recently?(minutes=1)
    self.created_at > Time.zone.now-minutes.minutes
  end

  # returns true if the user is ready to receive suggestions
  def suggestionable?
    self.checkins_count >= Checkin.min_checkins_for_suggestion
  end

  # add user badges based on location tags
  # note: usually called asynchronously
  def async_add_badges
    tag_names = locations.collect(&:tags).flatten.collect(&:name)
    Badge.all.each do |badge|
      matches = tag_names.grep(Regexp.new(badge.regex))
      if !matches.blank?
        badgings.create(:badge => badge)
      end
    end
  end

  def send_alert(options)
    case options[:id]
    when :linked_account
      options.update(:level => 'notice', :subject => 'checkins', :message => I18n.t('alert.linked_account'))
    when :need_checkins
      options.update(:level => 'notice', :subject => 'checkins', :message => I18n.t('alert.need_checkins'))
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

  # def manage_user_roles
  #   unless self.has_role?('user manager', self)
  #     # all users can manage themselves
  #     self.grant_role('user manager', self)
  #   end
  # end

  # send email after a user signup using delayed job
  def send_signup_email
    Delayed::Job.enqueue(EmailJob.new(:user_id => self.id, :object => 'user', :action => 'signup'), 0)
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

  # after_save callback to check for a facebook id
  def after_add_facebook_id
    if fbid = changes['facebook_id'].try(:[], 1)
      # check admin users
      if ADMIN_FACEBOOK_IDS.include?(fbid)
        self.grant_role('admin')
      end
    end
  end

  # user added a checkin
  def after_add_checkin(checkin)
    # add points for checkin
    self.add_points_for_checkin(checkin)
  end
  
end
