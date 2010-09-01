class Suggestion < ActiveRecord::Base
  has_one     :actor1, :class_name => 'UserSuggestion'
  has_one     :actor2, :class_name => 'UserSuggestion'
  belongs_to  :location

  # validates   :user1_action
  # validates   :user2_action
  validates   :state, :presence => true

  accepts_nested_attributes_for :actor1, :allow_destroy => true, :reject_if => proc { |attrs| attrs.all? { |k, v| v.blank? } }
  accepts_nested_attributes_for :actor2, :allow_destroy => true, :reject_if => proc { |attrs| attrs.all? { |k, v| v.blank? } }
  
  # BEGIN acts_as_state_machine
  include AASM
  aasm_column               :state
  aasm_initial_state        :suggested
  aasm_state                :suggested
  aasm_state                :rejected
  aasm_state                :rescheduling
  aasm_state                :confirming
  aasm_state                :confirmed

  aasm_event :reject do
    transitions :to => :rejected, :from => [:suggested, :rescheduling, :confirming, :rejected]
  end

  aasm_event :reschedule do
    transitions :to => :rescheduling, :from => [:suggested, :rescheduling, :confirming]
  end

  aasm_event :confirm do
    transitions :to => :confirming, :from => [:suggested, :rescheduling, :confirming]
  end

  aasm_event :complete do
    transitions :to => :confirmed, :from => [:confirming], :guard => :both_confirmed?
  end
  # END acts_as_state_machine

  def both_confirmed?
    return (actor1.confirmed? and actor2.confirmed?)
  end

end