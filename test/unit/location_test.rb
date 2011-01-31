require 'test_helper'

class LocationTest < ActiveSupport::TestCase
  should belong_to :country
  should belong_to :state
  should belong_to :city
  should belong_to :zipcode
  should belong_to :timezone
  should have_many :neighborhoods
  should have_many :email_addresses
  should have_many :phone_numbers
  should have_many :location_sources

  def setup
    WebMock.allow_net_connect!
  end

  context "location to_param" do
    should "default to location id if name is blank" do
      @location = Location.create!(:name => "Home", :country => countries(:us))
      assert_equal @location.id.to_s, @location.to_param
    end
  end

  # context "location tags delegate" do
  #   context "with no company" do
  #     setup do
  #       @location = Location.create(:name => "Home", :country => @us)
  #     end
  # 
  #     should "have empty tags collection" do
  #       assert_equal [], @location.tags
  #     end
  #   end
  #   
  #   context "with a company" do
  #     setup do
  #       @location = Location.create(:name => "Home", :country => @us)
  #       @company.locations.push(@location)
  #       @company.reload
  #     end
  #   
  #     should "have empty tags collection" do
  #       assert_equal ['beer', 'soccer'], @location.tags.collect(&:name)
  #     end
  #   end
  # end

  should "create with default country" do
    @location = Location.create!
    assert_equal countries(:us), @location.country
  end

  fast_context "location with country" do
    setup do
      @location = Location.create!(:country => countries(:us))
      @us       = countries(:us)
      @canada   = countries(:canada)
    end
    
    should "have us as locality, increment us.locations_count" do
      assert_equal [@us], @location.localities
      assert_equal 1, @us.reload.locations_count
    end

    should "have refer_to? == false" do
      assert_false @location.refer_to?
    end
    
    context "change country" do
      setup do
        @location.country = countries(:canada)
        @location.save
      end
    
      should "decrement us.locations_count, increment canada.locations_count" do
        assert_equal 0, @us.reload.locations_count
        assert_equal 1, @canada.reload.locations_count
      end
    end
  end
  
  fast_context "location with state" do
    setup do
      @il       = states(:il)
      @us       = countries(:us)
      @location = Location.create!(:name => "Home", :state => @il, :country => @us)
    end
    
    should "inherit state's country, increment illinois locations_count" do
      assert_equal @location.country, @il.country
      assert_equal 1, @il.reload.locations_count
    end
    
    fast_context "change state" do
      setup do
        @canada   = countries(:canada)
        @ontario  = states(:on)
        @location.state   = @ontario
        @location.country = @canada
        @location.save
      end
      
      should "change country to new state's country" do
        assert_equal @ontario.country, @location.country
      end
      
      should "decrement il,locations_count + us.locations_count, increment on.locations_count + canana.locations_count" do
        assert_equal 0, @il.locations_count
        assert_equal 0, @us.locations_count
        assert_equal 1, @ontario.reload.locations_count
        assert_equal 1, @canada.reload.locations_count
      end
    end
    
    fast_context "remove state" do
      setup do
        @location.state = nil
        @location.save
        @il.reload
      end

      should "decrement illinois.locations_count" do
        assert_equal 0, @il.locations_count
      end
    end
  end
  
  fast_context "location with a pre-defined city" do
    setup do
      @chicago  = cities(:chicago)
      @il       = states(:il)
      @us       = countries(:us)
      @location = Location.create!(:name => "Home", :city => @chicago, :country => @us)
    end
    
    should "increment chicago.locations_count, us.locations_count, set chicago.locations" do
      assert_equal 1, @chicago.reload.locations_count
      assert_equal 1, @us.reload.locations_count
      assert_equal [@location], @chicago.locations
    end

    fast_context "remove city" do
      setup do
        @location.city = nil
        @location.save
      end

      should "decrement chicago.locations_count, change chicago.locations" do
        assert_equal 0, @chicago.reload.locations_count
        assert_equal [], @chicago.locations
      end
    end
    
    fast_context "change city" do
      setup do
        @toronto  = cities(:toronto)
        @ontario  = states(:on)
        @canada   = countries(:canada)
        @location.city = @toronto
        @location.state = @ontario
        @location.country = @canada
        @location.save
      end

      should "remove chicago locations, set toronto.locations, change location state, country, change counters" do
        assert_equal [], @chicago.reload.locations
        assert_equal [@location], @toronto.reload.locations
        assert_equal @toronto.state, @location.state
        assert_equal @toronto.state.country, @location.country
        assert_equal 0, @chicago.locations_count
        assert_equal 0, @il.reload.locations_count
        assert_equal 0, @us.reload.locations_count
        assert_equal 1, @toronto.reload.locations_count
        assert_equal 1, @ontario.reload.locations_count
        assert_equal 1, @canada.reload.locations_count
      end
      
      # TODO: We should check the neighborhoods on a location when we change the location's city etc.
      # should "clear all existing neighborhoods not in the new city" do
      #   assert_equal @location.neighborhoods, []
      # end
    end
  end

  fast_context "location with a zipcode" do
    setup do
      @il       = states(:il)
      @us       = countries(:us)
      @zip      = zipcodes(:z60654)
      @location = Location.create!(:name => "Home", :zipcode => @zip, :country => @us)
    end
    
    should "increment zip locations_count" do
      assert_equal 1, @zip.reload.locations_count
    end

    should "set zip locations to [@location]" do
      assert_equal [@location], @zip.locations
    end

    should "increment us locations_count" do
      assert_equal 1, @us.reload.locations_count
    end
    
    fast_context "remove zipcode" do
      setup do
        @location.zipcode = nil
        @location.save
      end

      should "decrement zip locations_count" do
        assert_equal 0, @zip.reload.locations_count
      end

      should "remove zip locations" do
        assert_equal [], @zip.reload.locations
      end
    end
    
    fast_context "change zip" do
      setup do
        @zip2 = zipcodes(:z60610)
        @location.zipcode = @zip2
        @location.save
      end

      should "set 60654 locations to []" do
        assert_equal [], @zip.reload.locations
      end
      
      should "set 60610 locations to [@location]" do
        assert_equal [@location], @zip2.reload.locations
      end
    end
  end
  
  fast_context "location with a neighborhood" do
    setup do
      @us           = countries(:us)
      @river_north  = neighborhoods(:river_north)
      @location     = Location.create!(:name => "Home", :country => @us)
      @location.neighborhoods.push(@river_north)
      @location.reload
      @location.reload
      @river_north.reload
    end
    
    should "have neighborhood locality" do
      assert_contains @location.localities, @river_north
    end
    
    should "increment neighborhood and locations counter caches" do
      assert_equal 1, @river_north.locations_count
      assert_equal 1, @location.neighborhoods_count
    end
  
    should "set neighborhood locations to [@location]" do
      assert_equal [@location], @river_north.locations
    end

    should "assign neighborhood's city, state and country" do
      assert_equal @location.city, @river_north.city
      assert_equal @location.state, @river_north.city.state
      assert_equal @location.country, @river_north.city.state.country
    end
    
    should "increment city.locations_count" do
      assert_equal 1, @location.city.locations_count
    end

    should "increment state.locations_count" do
      assert_equal 1, @location.state.locations_count
    end

    should "increment country.locations_count" do
      assert_equal 1, @location.country.locations_count
    end

    fast_context "remove neighborhood" do
      setup do
        @location.neighborhoods.delete(@river_north)
        @location.reload
        @river_north.reload
      end

      should "set neighborhood locations to []" do
        assert_equal [], @river_north.locations
      end
      
      should "decrement neighborhood and locations counter caches" do
        assert_equal 0, @river_north.locations_count
        assert_equal 0, @location.neighborhoods_count
      end
    end
  end
  
  fast_context "location with a phone number" do
    setup do
      @location = Location.create(:name => "My Location", :country => @us)
      assert @location.valid?
      @phone    = @location.phone_numbers.create(:name => "Home", :address => "9991234567")
      assert @phone.valid?
    end
  
    should "have 1 phone number" do
      assert_equal ["9991234567"], @location.reload.phone_numbers.collect(&:address)
    end
    
    should "have phone_numbers_count == 1" do
      assert_equal 1, @location.reload.phone_numbers_count
    end
    
    should "have a primary phone number" do
      assert_equal "9991234567", @location.reload.primary_phone_number.address
    end
    
    should "cleanup after removing phone number" do
      @location.phone_numbers.delete(@phone)
      assert_nil PhoneNumber.find_by_id(@phone.id)
      assert_equal [], @location.reload.phone_numbers
      assert_equal 0, @location.reload.phone_numbers_count
    end
  end

  fast_context "location with an email address" do
    setup do
      @location = Location.create(:name => "My Location", :country => @us)
      assert @location.valid?
      @email    = @location.email_addresses.create(:address => "boozer@jarna.com")
      assert @email.valid?
    end
  
    should "have 1 email address" do
      assert_equal ["boozer@jarna.com"], @location.reload.email_addresses.collect(&:address)
    end
    
    should "have email_addresses_count == 1" do
      assert_equal 1, @location.reload.email_addresses_count
    end
    
    should "have a primary email address" do
      assert_equal "boozer@jarna.com", @location.primary_email_address.address
    end

    should "cleanup after removing email address" do
      @location.email_addresses.delete(@email)
      assert_nil EmailAddress.find_by_id(@email.id)
      assert_equal [], @location.email_addresses
      assert_equal 0, @location.reload.email_addresses_count
    end
  end

  context "marshalled source" do
    should "create with location source with address fields" do
      @location = Location.find_or_create_by_source(
                    :name => "Inteligentsia Coffee",
                    :source => "foursquare:44123",
                    :address => "53 W. Jackson Blvd.",
                    :city_state => "Chicago:IL",
                    :lat => "41.877901218486535",
                    :lng => "-87.62948513031006")
      assert_equal "53 W. Jackson Blvd.", @location.street_address
      assert_equal states(:il), @location.state
      assert_equal cities(:chicago), @location.city
      assert_equal 41.877901218486535, @location.lat
      assert_equal -87.62948513031006, @location.lng
      assert_equal ['foursquare'], @location.location_sources.collect(&:source_type)
      assert_equal ['44123'], @location.location_sources.collect(&:source_id)
    end

    should "create with location source without address fields" do
      @location = Location.find_or_create_by_source(
                    :name => "Inteligentsia Coffee",
                    :source => "foursquare:44123")
      assert_equal ['foursquare'], @location.location_sources.collect(&:source_type)
      assert_equal ['44123'], @location.location_sources.collect(&:source_id)
    end
  end

  context "reverse geocode" do
    should "ignore if location is not geocoded" do
      Delayed::Job.delete_all
      @location = Location.create!(:name => "Mary Janes Coffee Shop @ Hard Rock Hotel")
      assert_equal 0, match_delayed_jobs(/reverse_geocode/)
      assert_false @location.reverse_geocode
    end

    should "ignore if location has a street addresss" do
      Delayed::Job.delete_all
      @location = Location.create!(:name => "Mary Janes Coffee Shop @ Hard Rock Hotel",
                                   :street_address => "200 W Grand Ave")
      assert_equal 0, match_delayed_jobs(/reverse_geocode/)
      assert_false @location.reverse_geocode
    end

    should "ignore if location has a city" do
      Delayed::Job.delete_all
      @location = Location.create!(:name => "Mary Janes Coffee Shop @ Hard Rock Hotel",
                                   :city => cities(:chicago))
      assert_equal 0, match_delayed_jobs(/reverse_geocode/)
      assert_false @location.reverse_geocode
    end

    should "fill in street, city, state, zipcode, country for a san diego location" do
      Delayed::Job.delete_all
      # @ca       = Factory(:state, :name => 'California', :code => 'CA', :country => countries(:us))
      @location = Location.create!(:name => "Mary Janes Coffee Shop @ Hard Rock Hotel",
                                   :lat => 32.707664, :lng => -117.159876)
      assert_equal 1, match_delayed_jobs(/reverse_geocode/)
      work_off_delayed_jobs(/reverse_geocode/)
      assert_equal "209 5th Ave", @location.reload.street_address
      assert_equal "San Diego", @location.reload.city.name
      assert_equal "CA", @location.reload.state.code
      assert_equal "US", @location.reload.country.code
    end

    should "fill in street, city, state, country for a lake tahoe location" do
      Delayed::Job.delete_all
      # @ca       = Factory(:state, :name => 'California', :code => 'CA', :country => countries(:us))
      @location = Location.create!(:name => "Gar Woods",
                                   :lat => 39.22543, :lng => -120.083609)
      assert_equal 1, match_delayed_jobs(/reverse_geocode/)
      work_off_delayed_jobs(/reverse_geocode/)
      assert_equal "Lake Tahoe", @location.reload.city.name
      assert_equal "CA", @location.reload.state.code
      assert_equal "US", @location.reload.country.code
    end

    should "fill in street, city, state, country for a toronto location" do
      Delayed::Job.delete_all
      @location = Location.create!(:name => "Blowfish Restaurant & Saki bar",
                                   :lat => 43.6439338, :lng => -79.4025813)
      assert_equal 1, match_delayed_jobs(/reverse_geocode/)
      work_off_delayed_jobs(/reverse_geocode/)
      assert_equal "668 King St W", @location.reload.street_address
      assert_equal "Toronto", @location.reload.city.name
      assert_equal "ON", @location.reload.state.code
      assert_equal "CA", @location.reload.country.code
    end

    should "create country and fill in street, city for a hereford (london) location" do
      Delayed::Job.delete_all
      @location = Location.create!(:name => "Left Bank",
                                   :lat => 52.0528303, :lng => -2.7188012)
      assert_equal 1, match_delayed_jobs(/reverse_geocode/)
      work_off_delayed_jobs(/reverse_geocode/)
      assert_equal "St Martin'S St", @location.reload.street_address
      assert_equal "Hereford", @location.reload.city.name
      assert_equal "GB", @location.reload.country.code
    end
  end

  fast_context "location without refer_to" do
    setup do
      @location = Location.create(:name => "Home", :country => @us)
    end
    
    should "have refer_to? == false" do
      assert_equal false, @location.refer_to?
    end

    context "and add refer_to" do
      setup do
        @location.refer_to = 1001
        @location.save
      end

      should "have refer_to? == true" do
        assert_equal true, @location.refer_to?
      end
    end
  end
  
  context "location timezone" do
    context "where location timezone is set" do
      setup do
        @timezone  = timezones(:est)
        @location  = Location.create(:country => countries(:us), :state => states(:il), :city => cities(:chicago),
                                     :timezone => @timezone)
      end

      should "use location's timezone" do
        assert_equal @timezone, @location.timezone
      end
    end

    context "where location timezone is empty" do
      setup do
        @chicago = cities(:chicago)
        @chicago.timezone = timezones(:cst)
        @chicago.save
        @location = Location.create(:country => countries(:us), :state => states(:il), :city => @chicago)
      end

      should "use city's timezone" do
        assert_equal @chicago.timezone, @location.timezone
      end
    end

    context "where location city is empty" do
      setup do
        @location  = Location.create(:country => countries(:us), :state => states(:il))
      end

      should "have no timezone" do
        assert_equal nil, @location.timezone
      end
    end
  end

  context "hotness" do
    setup do
      @user1  = Factory(:user)
      @user2  = Factory(:user)
      @user3  = Factory(:user)
      @user4  = Factory(:user)
      @user5  = Factory(:user)
    end

    should "be 10 for location with 2 user checkins" do
      @location = Location.create(:country => countries(:us), :state => states(:il))
      @user1.locationships.create(:location => @location, :my_checkins => 1)
      @user2.locationships.create(:location => @location, :my_checkins => 1)
      assert_equal 10, @location.hotness
    end

    should "be 4 for location with 2 todo checkins" do
      @location = Location.create(:country => countries(:us), :state => states(:il))
      @user1.locationships.create(:location => @location, :todo_checkins => 1)
      @user2.locationships.create(:location => @location, :todo_checkins => 1)
      assert_equal 4, @location.hotness
    end

    should "be 19 for location with 3 user checkins and 2 todo checkins" do
      @location = Location.create(:name => "Location 1", :country => countries(:us), :state => states(:il))
      @user1.locationships.create(:location => @location, :my_checkins => 1)
      @user2.locationships.create(:location => @location, :my_checkins => 1)
      @user3.locationships.create(:location => @location, :my_checkins => 1)
      @user4.locationships.create(:location => @location, :todo_checkins => 1)
      @user5.locationships.create(:location => @location, :todo_checkins => 1)
      assert_equal 19, @location.hotness
    end
  end

  # context "merge locations" do
  #   setup do
  #     @location1  = Location.create(:country => @us, :state => @illinois, :city => @chicago)
  #     @phone1     = @location1.phone_numbers.create(:name => "Work", :address => "9999999999")
  #     @location1.location_sources.push(LocationSource.new(:location => @location1, :source_id => 1, :source_type => "Test"))
  #     @company1   = Company.create(:name => "Walnut Industries Chicago", :time_zone => "UTC")
  #     @company1.locations.push(@location1)
  #     @location1.reload
  #     @company1.tag_list.add("tag1")
  #     @company1.save
  #     
  #     @location2  = Location.create(:country => @us, :state => @illinois, :city => @chicago)
  #     @phone2     = @location2.phone_numbers.create(:name => "Work", :address => "2222222222")
  #     @location2.location_sources.push(LocationSource.new(:location => @location2, :source_id => 2, :source_type => "Test"))
  #     @company2   = Company.create(:name => "Walnut Industries San Francisco", :time_zone => "UTC")
  #     @company2.locations.push(@location2)
  #     @location2.reload
  #     @company2.tag_list.add("tag2")
  #     @company2.save
  #   end
  #   
  #   should_change("Location.count", :by => 2) { Location.count }
  #   # should_change("Company.count", :by => 2) { Company.count }
  #   should_change("PhoneNumber.count", :by => 2) { PhoneNumber.count }
  #   should_change("LocationSource.count", :by => 2) { LocationSource.count }
  #   
  #   context "and then merge locations" do
  #     setup do
  #       LocationHelper.merge_locations([@location1, @location2])
  #       @location1.reload
  #     end
  #     
  #     should_change("Location.count", :by => -1) { Location.count }
  #     # should_change("Company.count", :by => -1) { Company.count }
  #     should_not_change("PhoneNumber.count") { PhoneNumber.count }
  #     should_not_change("LocationSource.count") { LocationSource.count }
  #     
  #     should "add tags to location1" do
  #       assert_equal ["tag1", "tag2"], @location1.company.tag_list
  #     end
  #     
  #     should "add phone number to location1" do
  #       assert_equal ["9999999999", "2222222222"], @location1.phone_numbers.collect(&:address)
  #     end
  #     
  #     should "have phone_numbers_count == 2" do
  #       assert_equal 2, @location1.phone_numbers_count
  #     end
  #     
  #     should "add location source to location1" do
  #       assert_equal [1, 2], @location1.location_sources.collect(&:source_id)
  #     end
  #     
  #     should "remove company2" do
  #       assert_equal nil, Company.find_by_id(@company2.id)
  #     end
  #     
  #     should "remove location1" do
  #       assert_equal nil, Location.find_by_id(@location2.id)
  #     end
  #   end
  # end
  
end
