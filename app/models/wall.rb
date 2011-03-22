class Wall < ActiveRecord::Base
  belongs_to    :checkin
  belongs_to    :location
  has_many      :wall_messages
  validates     :checkin_id, :presence => true
  before_create :set_members

  def self.find_or_create(options={})
    @checkin = options[:checkin]
    @wall    = Wall.find_by_checkin_id(@checkin.id) || Wall.create(:checkin => @checkin, :location => @checkin.location)
  rescue Exception => e
    nil
  end

  # map member_set_ids string to a collection
  def member_set
    (self.member_set_ids || '').split(',').map(&:to_i)
  end

  protected

  # set members to user + user follower ids
  def set_members
    self.member_set_ids = (checkin.user.follower_ids + [checkin.user.id]).sort.join(',')
  end

end