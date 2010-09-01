class UserSuggestion < ActiveRecord::Base
  belongs_to  :suggestion
  belongs_to  :user
  
  validates   :state, :presence => true

  # BEGIN acts_as_state_machine
  include AASM
  aasm_column               :state
  aasm_initial_state        :signaled
  aasm_state                :signaled
  aasm_state                :rejected, :enter => :actor_rejected
  aasm_state                :rescheduled, :enter => :actor_rescheduled
  aasm_state                :confirmed, :enter => :actor_confirmed

  aasm_event :reject do
    transitions :to => :rejected, :from => [:signaled, :rescheduled, :confirmed, :rejected]
  end

  aasm_event :signal do
    transitions :to => :signaled, :from => [:rescheduled, :confirmed, :signaled]
  end

  aasm_event :reschedule do
    transitions :to => :rescheduled, :from => [:signaled, :rescheduled, :confirmed]
  end

  aasm_event :confirm do
    transitions :to => :confirmed, :from => [:signaled, :rescheduled]
  end
  # END acts_as_state_machine

  def actor_rejected
    suggestion.reject!
  end

  def actor_rescheduled
    suggestion.reschedule!
    actor = find_other_actor
    actor.signal!
  end

  def actor_confirmed
    suggestion.confirm!
    suggestion.complete!
  end

  protected
  
  def find_other_actor
    suggestion.actor1.id == self.id ? suggestion.actor2 : suggestion.actor1
  end

end