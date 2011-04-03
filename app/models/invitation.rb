class Invitation < ActiveRecord::Base
  belongs_to      :sender,        :class_name => 'User'
  validates       :sender_id,     :presence => true

  before_create   :generate_invitation_token
  after_create    :send_email

  attr_accessor   :list

  def send_email
    self.class.log("[user:#{sender.id}] #{sender.handle} invited #{recipient_email}")
    Resque.enqueue(UserMailerWorker, :user_invite, 'invitation_id' => self.id)
  end

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

  protected

  def generate_invitation_token
    self.token    = Devise.friendly_token
    self.sent_at  = Time.now.utc
  end

end