class Badge < ActiveRecord::Base
  validates   :name,  :presence => true, :uniqueness => true
  validates   :regex, :presence => true

  has_many    :badgings, :dependent => :destroy
  has_many    :users, :through => :badgings

  before_save :event_reset_tag_ids

  def translation
    name.to_s.downcase.gsub(' ', '_')
  end

  # minimum number of badges under which users get the default badge
  def self.default_min
    3
  end

  def self.default
    # build default badge
    @@default ||= Badge.new(:name => "Create your Social DNA")
  end

  # search for badges with the specified tag ids
  def self.search(tag_ids)
    Array(tag_ids).collect do |tag_id|
      Badge.find(:all, :conditions => ["find_in_set(?,tag_ids)", tag_id])
    end.flatten
  end

  def event_reset_tag_ids(force=false)
    if changes[:regex] or force
      # find tag ids based on new regex
      tokens  = regex.try(:split, '|') || []
      tag_ids = tokens.map{ |s| ActsAsTaggableOn::Tag.find_by_name(s).try(:id) }.compact
      # set new tag ids
      self.tag_ids = tag_ids.join(',')
    end
  end

end