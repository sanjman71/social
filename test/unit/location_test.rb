require 'test_helper'

class LocationTest < ActiveSupport::TestCase

  should belong_to :country
  should belong_to :state
  should belong_to :city
  should belong_to :zip
  should belong_to :timezone
  should have_many :neighborhoods
  should have_many :email_addresses
  should have_many :phone_numbers
  should have_many :neighbors
  should have_many :location_sources

  def setup
    @us           = Factory(:us)
    @canada       = Factory(:canada)
    @il           = Factory(:il, :country => @us)
    @on           = Factory(:ontario, :country => @canada)
    @chicago      = Factory(:chicago, :state => @il, :timezone => Factory(:timezone_chicago))
    @toronto      = Factory(:toronto, :state => @on)
    @zip          = Factory(:zip, :name => "60654", :state => @il)
    @river_north  = Factory(:neighborhood, :name => "River North", :city => @chicago)
  end

  context "location to_param" do
    should "default to location id if name is blank" do
      @location = Location.create(:name => "Home", :country => @us)
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

  context "location with country" do
    setup do
      @location = Location.create(:country => @us)
      assert @location.valid?
      @us.reload
    end
    
    should "have us as locality, increment us.locations_count" do
      assert_equal [@us], @location.localities
      assert_equal 1, @us.locations_count
    end

    should "have refer_to? == false" do
      assert_equal false, @location.refer_to?
    end
    
    context "change country" do
      setup do
        @location.country = @canada
        @location.save
        @us.reload
        @canada.reload
      end
    
      should "decrement us.locations_count, increment canada.locations_count" do
        assert_equal 0, @us.locations_count
        assert_equal 1, @canada.locations_count
      end
    end
  end
  
  context "location with state" do
    setup do
      @location = Location.create(:name => "Home", :state => @il, :country => @us)
      assert @location.valid?
      @il.reload
    end
    
    should "inherit state's country, increment illinois locations_count" do
      assert_equal @location.country, @il.country
      assert_equal 1, @il.locations_count
    end
    
    context "change state" do
      setup do
        @location.state = @on
        @location.country = @canada
        @location.save
        @on.reload
        @il.reload
        @us.reload
        @canada.reload
      end
      
      should "change country to new state's country" do
        assert_equal @on.country, @location.country
      end
      
      should "decrement il,locations_count + us.locations_count, increment on.locations_count + canana.locations_count" do
        assert_equal 0, @il.locations_count
        assert_equal 0, @us.locations_count
        assert_equal 1, @on.locations_count
        assert_equal 1, @canada.locations_count
      end
    end
    
    context "remove state" do
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
  
  context "location with a pre-defined city" do
    setup do
      @location = Location.create(:name => "Home", :city => @chicago, :country => @us)
      assert @location.valid?
      @location.reload
      @chicago.reload
      @us.reload
    end
    
    should "increment chicago.locations_count, us.locations_count, set chicago.locations" do
      assert_equal 1, @chicago.locations_count
      assert_equal 1, @us.locations_count
      assert_equal [@location], @chicago.locations
    end

    context "remove city" do
      setup do
        @location.city = nil
        @location.save
        @chicago.reload
      end

      should "decrement chicago.locations_count, change chicago.locations" do
        assert_equal 0, @chicago.locations_count
        assert_equal [], @chicago.locations
      end
    end
    
    context "change city" do
      setup do
        @location.city = @toronto
        @location.state = @on
        @location.country = @canada
        @location.save
        @chicago.reload
        @us.reload
        @toronto.reload
        @on.reload
        @canada.reload
      end

      should "remove chicago locations, set toronto.locations, change location state, country, change counters" do
        assert_equal [], @chicago.locations
        assert_equal [@location], @toronto.locations
        assert_equal @toronto.state, @location.state
        assert_equal @toronto.state.country, @location.country
        assert_equal 0, @chicago.locations_count
        assert_equal 0, @il.locations_count
        assert_equal 0, @us.locations_count
        assert_equal 1, @toronto.locations_count
        assert_equal 1, @on.locations_count
        assert_equal 1, @canada.locations_count
      end
      
      # TODO: We should check the neighborhoods on a location when we change the location's city etc.
      # should "clear all existing neighborhoods not in the new city" do
      #   assert_equal @location.neighborhoods, []
      # end
    end
  end

  # context "location with city and state" do
  #   setup do
  #     @location = Location.create(:city => @chicago, :state => @il, :country => @us)
  #   end
  # 
  #   should_change("Location.count", :by => 1) { Location.count }
  # 
  #   should "increment city locations_count" do
  #     assert_equal 1, @chicago.reload.locations_count
  #   end
  # 
  #   should "increment state locations_count" do
  #     assert_equal 1, @il.reload.locations_count
  #   end
  # 
  #   should "increment country locations_count" do
  #     assert_equal 1, @us.reload.locations_count
  #   end
  # end
  
  context "location with a zip" do
    setup do
      @location = Location.create(:name => "Home", :zip => @zip, :country => @us)
      assert @location.valid?
      @zip.reload
      @il.reload
      @us.reload
    end
    
    should "increment zip locations_count" do
      assert_equal 1, @zip.locations_count
    end

    should "set zip locations to [@location]" do
      assert_equal [@location], @zip.locations
    end

    should "increment us locations_count" do
      assert_equal 1, @us.locations_count
    end
    
    context "remove zip" do
      setup do
        @location.zip = nil
        @location.save
        @zip.reload
      end

      should "decrement zip locations_count" do
        assert_equal 0, @zip.locations_count
      end

      should "remove zip locations" do
        assert_equal [], @zip.locations
      end
    end
    
    context "change zip" do
      setup do
        @zip2 = Factory(:zip, :name => "60610", :state => @il)
        @location.zip = @zip2
        @location.save
        @zip2.reload
        @zip.reload
      end

      should "set 60654 locations to []" do
        assert_equal [], @zip.locations
      end
      
      should "set 60610 locations to [@location]" do
        assert_equal [@location], @zip2.locations
      end
    end
  end
  
  context "location with a neighborhood" do
    setup do
      @location = Location.create(:name => "Home", :country => @us)
      assert @location.valid?
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

    context "remove neighborhood" do
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
  
  context "location with a phone number" do
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
    
    context "then remove phone number" do
      setup do
        @location.phone_numbers.delete(@phone)
      end

      should "have no phone number, decrement counter cache" do
        assert_nil PhoneNumber.find_by_id(@phone.id)
        assert_equal [], @location.reload.phone_numbers
        assert_equal 0, @location.reload.phone_numbers_count
      end
    end
  end

  context "location with an email address" do
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

    context "then remove email address" do
      setup do
        @location.email_addresses.delete(@email)
      end
      
      should "have no email address, decrement counter cache" do
        assert_nil EmailAddress.find_by_id(@email.id)
        assert_equal [], @location.email_addresses
        assert_equal 0, @location.reload.email_addresses_count
      end
    end
  end

  context "location without refer_to" do
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
        @timezone  = Factory(:timezone, :name => "America/New_York")
        @location  = Location.create(:country => @us, :state => @illinois, :city => @chicago, :timezone => @timezone)
      end

      should "use location's timezone" do
        assert_equal @timezone, @location.timezone
      end
    end

    context "where location timezone is empty" do
      setup do
        @location  = Location.create(:country => @us, :state => @illinois, :city => @chicago)
      end

      should "use city's timezone" do
        assert_equal @chicago.timezone, @location.timezone
      end
    end
    
    context "where location city is empty" do
      setup do
        @location  = Location.create(:country => @us, :state => @illinois)
      end

      should "have no timezone" do
        assert_equal nil, @location.timezone
      end
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
