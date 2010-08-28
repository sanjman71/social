class Checkin < ActiveRecord::Base
  validates   :user_id, :presence => true
  validates   :location_id, :presence => true
  validates   :checkin_at, :presence => true
  validates   :source_id, :presence => true
  validates   :source_type, :presence => true
  # allow at most 1 checkin per location
  validates_uniqueness_of :user_id, :scope => [:location_id, :source_id, :source_type]
  belongs_to  :location
  belongs_to  :user

  # import a foursquare checkin hash
  # e.g. {"id"=>141731194, "created"=>"Sun, 22 Aug 10 23:16:33 +0000", "timezone"=>"America/Chicago",
  #       "venue"=>{"id"=>4172889, "name"=>"Zed 451", "address"=>"763 N. Clark St.", "city"=>"Chicago", "state"=>"Illinois",
  #                 "geolat"=>41.8964066, "geolong"=>-87.6312161}
  #      }
  def self.import_foursquare_checkin(user, checkin_hash)
    # map foursquare venue to a location
    @location = LocationImport.import_foursquare_venue(checkin_hash['venue'])
    if @location.blank?
      raise Exception, "Foursquare invalid location"
    end
    
    # add checkin
    options  = Hash[:location => @location, :checkin_at => Time.zone.now, :source_id => checkin_hash['id'], :source_type => 'fs']
    @checkin = user.checkins.find_by_source_id_and_source_type(options[:source_id], options[:source_type])
    @checkin ||= user.checkins.create(options)
  end
end