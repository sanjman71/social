class LocationSource < ActiveRecord::Base
  belongs_to              :location
  belongs_to              :source, :polymorphic => true
  validates_presence_of   :location_id
  validates_presence_of   :source_id
  validates_presence_of   :source_type
  validates_uniqueness_of :location_id, :scope => [:source_id, :source_type]
  after_create            :add_tags

  # find location with the specified source
  scope :with_source,        lambda { |source| { :conditions => {:source_id => source.id, :source_type => source.class.to_s} }}
  scope :with_source_id,     lambda { |source_id| { :conditions => {:source_id => source_id.to_i} }}
  scope :with_source_type,   lambda { |source_type| { :conditions => {:source_type => source_type} }}
  scope :facebook,           where("source_type = 'facebook'")
  scope :foursquare,         where("source_type = 'foursquare'")

  def facebook?
    self.source_type == 'facebook'
  end

  def foursquare?
    self.source_type == 'foursquare'
  end

  # add tags to this location
  def add_tags
    # check if already tagged
    return false if self.tagged_at?
    case
    when facebook?
      FacebookLocation.import_tags(:location_sources => [self])
    when foursquare?
      FoursquareLocation.import_tags(:location_sources => [self])
    end
  end

end