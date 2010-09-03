class Suggestion < ActiveRecord::Base
  has_many    :actors, :class_name => "UserSuggestion"
  has_one     :actor1, :class_name => 'UserSuggestion', :order => 'id asc'
  has_one     :actor2, :class_name => 'UserSuggestion', :order => 'id desc'
  belongs_to  :location

  validates   :state, :presence => true

  accepts_nested_attributes_for :actor1, :allow_destroy => true, :reject_if => proc { |attrs| attrs.all? { |k, v| v.blank? } }
  accepts_nested_attributes_for :actor2, :allow_destroy => true, :reject_if => proc { |attrs| attrs.all? { |k, v| v.blank? } }
  
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

  def user_declines(actor)
    actor.decline!
    log(:ok, "#{actor.user.handle} declined")
    @other_actor = other_actor(actor) 
    @other_actor.dump!
    log(:ok, "#{@other_actor.user.handle} dumped")
    bail!
    @other_actor.message!(@@message_declined % actor.user.handle)
    log(:ok, "bailed")
  end

  def user_schedules(actor)
    actor.schedule!
    log(:ok, "#{actor.user.handle} scheduled")
    @other_actor = other_actor(actor) 
    @other_actor.schedule!
    log(:ok, "#{@other_actor.user.handle} changed to scheduled")
    talk!
    @other_actor.message!(@@message_scheduled % actor.user.handle)
    log(:ok, "talking")
  end

  def user_reschedules(actor)
    actor.reschedule!
    log(:ok, "#{actor.user.handle} rescheduled")
    @other_actor = other_actor(actor) 
    @other_actor.reschedule!
    @other_actor.message!(@@message_rescheduled % actor.user.handle)
    log(:ok, self.state)
  end

  def user_confirms(actor)
    actor.confirm!
    log(:ok, "#{actor.user.handle} confirmed")
    @other_actor = other_actor(actor)
    log(:ok, self.state)
    @other_actor.message!(@@message_confirmed % actor.user.handle)
    if actor.confirmed? and @other_actor.confirmed?
      # both have confirmed
      go_out!
      log(:ok, "going out")
    end
  end

  # messages
  @@message_initialized   = "A suggested date"
  @@message_declined      = "%s declined"
  @@message_scheduled     = "%s suggested a date and time"
  @@message_rescheduled   = "%s suggested another date and time"
  @@message_confirmed     = "%s confirmed"

  protected

  # def both_confirmed?
  #   return (actor1.confirmed? and actor2.confirmed?)
  # end

  def other_actor(actor)
    actor1.id == actor.id ? actor2 : actor1
  end

  def log(level, s, options={})
    SUGGESTIONS_LOGGER.debug("#{Time.now}: [#{level}] suggestion:#{self.id} #{s}")
  end

end