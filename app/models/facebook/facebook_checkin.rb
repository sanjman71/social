class FacebookCheckin
  
  # import a facebook checkin hash
  # e.g. {"id"=>141731194, "from"=>{"name"=>"Sanjay Kapoor", "id"=>"633015812"},
  #       "place"=>{"id"=>"117669674925118", "name"=>"Bull & Bear",
  #                 "location"=>{"street"=>"431 N Wells St", "city"=>"Chicago", "state"=>"IL", "zip"=>"60654-4512",
  #                              "latitude"=>41.890177, "longitude"=>-87.633815}},
  #       "application"=>nil, "created_time"=>"2010-08-28T22:33:53+0000"}
  def self.import_checkin(user, checkin_hash)
    # import location
    @location = LocationImport.import_facebook_place(checkin_hash['place'])
    if @location.blank?
      raise Exception, "invalid location #{checkin_hash['place']}"
    end

    # add checkin
    options  = Hash[:location => @location, :checkin_at => Time.zone.now, :source_id => checkin_hash['id'].to_s, :source_type => Source.facebook_type]
    @checkin = user.checkins.find_by_source_id_and_source_type(options[:source_id], options[:source_type])
    @checkin ||= user.checkins.create(options)
  end

end