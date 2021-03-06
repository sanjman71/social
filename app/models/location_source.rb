class LocationSource < ActiveRecord::Base
  belongs_to              :location
  belongs_to              :source, :polymorphic => true
  # validates_presence_of   :location_id  # not allowed with nested attributes
  validates_presence_of   :source_id
  validates_presence_of   :source_type
  validates_uniqueness_of :location_id, :scope => [:source_id, :source_type]
  after_create            :event_location_source_created

  # BEGIN acts_as_state_machine
  include AASM
  aasm_column           :state
  aasm_initial_state    :initialized
  aasm_state            :initialized
  aasm_state            :tagging
  aasm_state            :tagged, :enter => :event_location_source_tagged

  aasm_event :tagging do
    transitions :to => :tagging, :from => [:initialized]
  end

  aasm_event :tagged do
    transitions :to => :tagged, :from => [:tagging]
  end
  # END acts_as_state_machine

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

  def event_location_source_created
    # log
    self.class.log("[location:#{location_id}] #{location.name} mapped to #{self.source_type}:#{self.source_id} and location_source:#{id}")
    # add tags
    add_tags
    # add other sources
    add_other_sources
  end

  # add other location sources to this location
  def add_other_sources
    case
    when facebook?
      # location has a facebook mapping, try adding a foursquare mapping
      Resque.enqueue(FoursquareWorker, :map_location, 'location_ids' => [location.id], 'location_sources' => [id])
    end
    true
  end

  # add tags to this location
  def add_tags
    # check if already tagged
    return false if tagged?
    case
    when facebook?
      Resque.enqueue(FacebookWorker, :import_tags, 'location_sources' => [id])
    when foursquare?
      Resque.enqueue(FoursquareWorker, :import_tags, 'location_sources' => [id])
    end
    tagging!
  end

  # mark attributes after a location source is tagged
  def event_location_source_tagged
    # set tag count and timestamp
    # SK: not sure setting the tag count means much because tags can be imported from multiple sources
    self.tag_count  = location.tag_list.size
    self.tagged_at  = Time.zone.now
    self.save
    # propagate event to location
    location.try(:event_location_tagged)
  end

  def self.log(s, level = :info)
    AppLogger.log(s, nil, level)
  end

end