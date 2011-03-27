class Wall < ActiveRecord::Base
  belongs_to    :checkin
  belongs_to    :location
  has_many      :wall_messages, :dependent => :destroy
  has_many      :messages, :class_name => 'WallMessage', :foreign_key => :wall_id
  validates     :checkin_id, :presence => true
  before_create :set_members

  def self.find_or_create(options={})
    @checkin = options[:checkin]
    @wall    = Wall.find_by_checkin_id(@checkin.id) ||
               Wall.create(:checkin => @checkin, :location => @checkin.location, :updated_at => @checkin.checkin_at)
  rescue Exception => e
    nil
  end

  def self.find_all_by_member(user)
    user_id = user.id rescue user
    Wall.find(:all, :conditions => ["find_in_set(?,member_set_ids)", user_id], :order => "updated_at desc")
  end

  def self.find_by_member(user)
    user_id = user.id rescue user
    Wall.find(:first, :conditions => ["find_in_set(?,member_set_ids)", user_id], :order => "updated_at desc")
    # Wall.select(:find_in_set[:member_set_ids, user_id])
  end

  def name
    location.present? ? location.name : "Chalkboard #{id}"
  end

  # map member_set_ids string to a collection
  def member_set
    (self.member_set_ids || '').split(',').map(&:to_i)
  end

  def member_handles
    User.find(member_set, :select => 'handle').collect(&:handle)
  end

  protected

  # set members to user + user follower ids
  def set_members
    self.member_set_ids = (checkin.user.follower_ids + [checkin.user.id]).sort.join(',')
  end

end