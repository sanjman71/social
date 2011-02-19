class Badge < ActiveRecord::Base
  validates   :name,  :presence => true, :uniqueness => true
  validates   :tagline, :presence => true

  has_many    :badgings, :dependent => :destroy
  has_many    :users, :through => :badgings

  before_save :event_reset_tag_ids
  after_save  :event_badge_saved

  def translation
    name.to_s.downcase.gsub(' ', '_')
  end

  def tag_names
    regex.split('|') rescue []
  end

  # add tags using the specified string or array tag list
  def add_tags(tag_list)
    if tag_list.is_a?(String)
      tag_list = tag_list.split(',').map(&:strip)
    end
    tag_list  += tag_names
    self.regex = tag_list.sort.join("|")
    self.save
  end

  # remove tags using the specified string or array tag list
  def remove_tags(tag_list)
    if tag_list.is_a?(String)
      tag_list = tag_list.split(',').map(&:strip)
    end
    # remove tag_list from existing tag_names
    tag_list_new  = tag_names - tag_list
    self.regex    = tag_list_new.sort.join("|")
    self.save
  end

  # minimum number of badges under which users get the default badge
  def self.default_min
    3
  end

  def self.default
    # build default badge
    @@default ||= Badge.new(:name => "Create your Social DNA",
                            :tagline => "Check in to places in order to build your profile")
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

  def event_badge_saved
    if changes[:regex]
      # queue badge discovery
      Resque.enqueue(BadgeWorker, :async_badge_discovery)
    end
  end

end