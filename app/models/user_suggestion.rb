class UserSuggestion < ActiveRecord::Base
  belongs_to    :suggestion
  belongs_to    :user
  
  validates     :state, :presence => true
  validates     :user_id, :presence => true, :uniqueness => {:scope => :suggestion_id}
  # validates     :suggestion_id, :presence => true # doesn't work with nested attributes

  delegate      :handle, :to => :user

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
    transitions :to => :declined, :from => [:initialized, :scheduled, :confirmed]
  end

  aasm_event :dump do
    transitions :to => :dumped, :from => [:initialized, :scheduled, :confirmed]
  end

  aasm_event :schedule do
    transitions :to => :scheduled, :from => [:initialized]
  end

  aasm_event :reschedule do
    transitions :to => :scheduled, :from => [:scheduled, :confirmed]
  end

  aasm_event :relocate do
    transitions :to => :scheduled, :from => [:scheduled, :confirmed]
  end

  aasm_event :confirm do
    transitions :to => :confirmed, :from => [:scheduled]
  end
  # END acts_as_state_machine

  def self.max_suggestions
    1
  end

  def event!(s)
    self.update_attribute(:event, s)
  end

  def alert!(b=true)
    self.update_attribute(:alert, b)
  end

  protected
  
  def other_actor
    @other_actor ||= suggestion.actor1.id == self.id ? suggestion.actor2 : suggestion.actor1
  end

  def before_create_callback
    self.alert = true
  end

end