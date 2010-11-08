class Suggestion < ActiveRecord::Base
  has_many      :parties, :class_name => "UserSuggestion", :dependent => :destroy
  has_one       :party1, :class_name => 'UserSuggestion', :order => 'user_suggestions.user_id asc'
  has_one       :party2, :class_name => 'UserSuggestion', :order => 'user_suggestions.user_id desc'
  has_many      :users, :through => :parties, :source => :user
  # has_one       :user1, :through => :party1, :source => :user
  # has_one       :user2, :through => :party2, :source => :user
  belongs_to    :creator, :class_name => 'User'
  belongs_to    :location

  validates     :state, :presence => true
  validates     :location_id, :presence => true
  after_create  :after_create_callback

  accepts_nested_attributes_for :party1, :allow_destroy => true, :reject_if => proc { |attrs| attrs.all? { |k, v| v.blank? } }
  accepts_nested_attributes_for :party2, :allow_destroy => true, :reject_if => proc { |attrs| attrs.all? { |k, v| v.blank? } }

  # BEGIN acts_as_state_machine
  include AASM
  aasm_column               :state
  aasm_initial_state        :initialized
  aasm_state                :initialized
  aasm_state                :talking
  aasm_state                :going_out
  aasm_state                :bailed
  
  aasm_event :talk do
    transitions :to => :talking, :from => [:initialized, :talking]
  end

  aasm_event :go_out do
    transitions :to => :going_out, :from => [:talking]
  end

  aasm_event :bail do
    transitions :to => :bailed, :from => [:initialized, :talking]
  end
  # END acts_as_state_machine

  # active suggestions have not been marked as bailed
  scope       :active, where("suggestions.state != 'bailed'")

  def scheduled_at=(t)
    if t.is_a?(String)
      # convert string to datetime
      case
      when match = t.match(/^(\d{2,2})\/(\d{2,2})\/(\d{4,4})$/)
        # e.g. 08/01/2010
        t = Time.zone.parse("#{match[3]}#{match[1]}#{match[2]}")
      when match = t.match(/^(\d{8,8})/)
        # e.g. 20100501
        t = Time.zone.parse(t)
      end
    end
    super(t)
  end

  def party_declines(party, options={})
    party.decline!
    party.event!('decline')
    party.alert!(false)
    @other_party = other_party(party) 
    @other_party.dump!
    @other_party.event!('dump')
    @other_party.alert!
    bail!
    log("[suggestion:#{self.id}] #{party.handle} declined, #{@other_party.handle} dumped, suggestion bailed")
  end

  def party_schedules(party, options={})
    self.scheduled_at = options[:scheduled_at]
    party.schedule!
    party.event!(options[:event] || 'schedule')
    party.alert!(false)
    @other_party = other_party(party) 
    @other_party.schedule!
    @other_party.event!('')
    @other_party.alert!
    talk!
    log("[suggestion:#{self.id}] #{party.handle} scheduled, #{@other_party.handle} changed to scheduled, suggestion talking")
  end

  def party_reschedules(party, options={})
    self.scheduled_at = options[:rescheduled_at]
    party.reschedule!
    party.event!(options[:event] || 'reschedule')
    @other_party = other_party(party) 
    @other_party.reschedule!
    @other_party.event!('')
    @other_party.alert!
    save!
    log("[suggestion:#{self.id}] #{party.handle} rescheduled, suggestion #{self.state}")
  end

  def party_confirms(party, options={})
    party.confirm!
    party.event!(options[:event] || 'confirm')
    @other_party = other_party(party)
    log("[suggestion:#{self.id}] #{party.handle} confirmed, suggestion #{self.state}")
    @other_party.event!('')
    @other_party.alert!
    if party.confirmed? and @other_party.confirmed?
      # both parties have confirmed
      go_out!
      log("[suggestion:#{self.id}] suggestion going out")
    end
  end

  def other_party(party)
    case
    when party.is_a?(UserSuggestion)
      party1.id == party.id ? party2 : party1
    when party.is_a?(User)
      party1.user_id == party.id ? party2 : party1
    end
  end

  def my_party(party)
    case
    when party.is_a?(UserSuggestion)
      party1.id == party.id ? party1 : party2
    when party.is_a?(User)
      party1.user_id == party.id ? party1 : party2
    end
  end

  protected

  def after_create_callback
    log("[suggestion:#{self.id}] creator:#{creator.try(:id).to_i}, users:#{party1.try(:user).try(:handle)}:#{party2.try(:user).try(:handle)}, when:#{self.when}")
  end

  def log(s, level = :info)
    self.class.log(s, level)
  end

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

end