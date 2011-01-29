class InvitePoke < ActiveRecord::Base
  belongs_to      :invitee, :class_name => 'User'
  belongs_to      :poker, :class_name => 'User'
  belongs_to      :friend, :class_name => 'User'

  validates       :invitee_id, :presence => true
  validates       :poker_id, :presence => true
  validates       :friend_id, :presence => true

  after_create    :send_email

  def self.find_or_create(invitee, poker, friend=nil)
    if friend.blank?
      # find member friend
      friends = invitee.friends.member + invitee.inverse_friends.member
      friend  = friends.sort_by(&:id).first
    end

    # check for any past pokes
    past_poke = self.where(:invitee_id => invitee.id, :poker_id => poker.id).first
    return past_poke if past_poke.present?

    # create new poke
    self.create(:invitee => invitee, :poker => poker, :friend => friend)
  end

  def send_email
    UserMailer.delay.user_invite_poke(:invite_poke_id => self.id)
  end
  
end