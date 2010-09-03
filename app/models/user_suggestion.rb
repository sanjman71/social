class UserSuggestion < ActiveRecord::Base
  belongs_to    :suggestion
  belongs_to    :user
  
  validates     :state, :presence => true

  before_create :before_create_callback

  # BEGIN acts_as_state_machine
  include AASM
  aasm_column               :state
  aasm_initial_state        :initialized
  aasm_state                :initialized
  aasm_state                :declined
  aasm_state                :dumped
  aasm_state                :scheduled
  aasm_state                :confirmed

  aasm_event :decline do
    transitions :to => :declined, :from => [:initialized, :scheduled, :confirmed, :declined]
  end

  aasm_event :dump do
    transitions :to => :dumped, :from => [:initialized, :scheduled, :confirmed, :dumped]
  end

  aasm_event :schedule do
    transitions :to => :scheduled, :from => [:initialized]
  end

  aasm_event :reschedule do
    transitions :to => :scheduled, :from => [:scheduled, :confirmed]
  end

  aasm_event :confirm do
    transitions :to => :confirmed, :from => [:scheduled, :confirmed]
  end
  # END acts_as_state_machine

  def message!(s)
    self.update_attribute(:message, s)
  end

  # messages

  @@message_initialized   = "A suggested date"
  @@message_declined      = "%s declined"
  @@message_scheduled     = "%s suggested a date and time"
  @@message_rescheduled   = "%s suggested another date and time"
  @@message_confirmed     = "%s confirmed"

  protected
  
  def other_actor
    @other_actor ||= suggestion.actor1.id == self.id ? suggestion.actor2 : suggestion.actor1
  end

  def before_create_callback
    self.message = @@message_initialized if self.message.blank?
  end

  def log(level, s, options={})
    SUGGESTIONS_LOGGER.debug("#{Time.now}: [#{level}] suggestion:#{suggestion.id} #{s}")
  end

end