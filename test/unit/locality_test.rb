require 'test_helper'

class LocalityTest < ActiveSupport::TestCase
  fixtures :all

  def setup
    WebMock.allow_net_connect!
    @us = countries(:us)
  end

  context "geocode country" do
    context "united states" do
      setup do
        @object = Locality.resolve("united states")
      end

      should "resolve to us country object" do
        assert_equal @us, @object
      end
    end

    context "us" do
      setup do
        @object = Locality.resolve("united states")
      end
      
      should "resolve to us country object" do
        assert_equal @us, @object
      end
    end
  end
  
  context "geocode state" do
    context "illinois" do
      setup do
        @il     = states(:il)
        @object = Locality.resolve("illinois")
      end

      should "resolve to illinois state object" do
        assert_equal @il, @object
      end
    end
    
    context "north carolina" do
      setup do
        @nc     = Factory(:state, :name => "North Carolina", :code => "NC", :country => @us)
        @object = Locality.resolve("north carolina")
      end

      should "resolve to north carolina state object" do
        assert_equal @nc, @object
      end
    end

    context "south carolina" do
      setup do
        @sc     = Factory(:state, :name => "South Carolina", :code => "SC", :country => @us)
        @object = Locality.resolve("south carolina")
      end

      should "resolve to south carolina state object" do
        assert_equal @sc, @object
      end
    end
  end

  context "geocode us city" do
    context "chicago, precision default" do
      setup do
        @chicago  = cities(:chicago)
        @object   = Locality.resolve("chicago")
      end

      should "resolve to chicago city object" do
        assert_equal @chicago, @object
      end
    end
    
    context "charlotte, precision default" do
      setup do
        @nc         = Factory(:state, :name => "North Carolina", :code => "NC", :country => @us)
        @charlotte  = Factory(:city, :name => "Charlotte", :state => @nc)
        @object     = Locality.resolve("charlotte")
      end

      should "resolve to charlotte city object" do
        assert_equal @charlotte, @object
      end
    end
    
    context "street address, precision city" do
      setup do
        @chicago  = cities(:chicago)
        @object   = Locality.resolve("200 w grand, chicago", :precision => :city)
      end
      
      should "resolve to chicago city object" do
        assert_equal @chicago, @object
      end
    end

    context "street address, precision city, create city" do
      setup do
        @object = Locality.resolve("200 w grand, chicago", :precision => :city, :create => true)
      end
      
      should "create chicago city object" do
        assert @object.is_a?(City)
        assert_equal 'Chicago', @object.name
      end
    end
  end

  context "geocode international city" do
    setup do
      @fr = Country.create!(:name => 'France', :code => 'FR')
    end
    
    should "create paris city object" do
      @object = Locality.resolve("paris", :precision => :city, :create => true)
      assert @object.is_a?(City)
      assert_equal 'Paris', @object.name
      assert_equal 'France', @object.country.name
    end
  end

  context "check city" do
    context "mis-spelled city la grange pk" do
      setup do
        @il         = states(:il)
        @la_grange  = Factory(:city, :name => "La Grange Park", :state => @il)
        @object     = Locality.check(@il, 'city', "La Grange Pk")
      end

      should "normalize and validate to la grange city object" do
        assert_equal @la_grange, @object
      end
    end
    
    context "wrong city in state" do
      setup do
        @il         = states(:il)
        @ca         = states(:ca)
        @chicago    = Factory(:city, :name => "Chicago", :state => @ca)
        @exception  = assert_raise(LocalityError) { Locality.check(@ca, 'city', "Chicago") }
      end

      should "thrown an invalid city exception" do
        assert_match(/invalid city/i, @exception.message)
      end
    end
  end
  
  context "geocode zip" do
    context "60654" do
      setup do
        @zip      = zipcodes(:z60654)
        @object   = Locality.resolve("60654")
      end

      should "resolve to illinois zip object" do
        assert_equal @zip, @object
      end
    end

    context "28212" do
      setup do
        @nc       = Factory(:state, :name => "North Carolina", :code => "NC", :country => @us)
        @zip      = Factory(:zipcode, :name => "28212", :state => @nc)
        @object   = Locality.resolve("28212")
      end

      should "resolve to north carolina zip object" do
        assert_equal @zip, @object
      end
    end
  end
  
  context "find city, state code" do
    setup do
      @il           = states(:il)
      @chicago      = cities(:chicago)
      @heights      = Factory(:city, :name => "Chicago Heights", :state => @il)
      @z60610       = zipcodes(:z60610)
      @river_north  = neighborhoods(:river_north)
    end
    
    context "when its well-formed" do
      should "find 'Chicago, IL'" do
        @where  = "Chicago, IL"
        @object = Locality.search(@where)
        assert_equal @chicago, @object
      end
      
      should "find 'chicago, IL'" do
        @where  = "chicago, IL"
        @object = Locality.search(@where)
        assert_equal @chicago, @object
      end

      should "find 'chicago IL'" do
        @where = "chicago IL"
        @object = Locality.search(@where)
        assert_equal @chicago, @object
      end

      should "find 'Chicago Heights, IL'" do
        @where  = "Chicago Heights, IL"
        @object = Locality.search(@where)
        assert_equal @heights, @object
      end

      should "find 'Chicago , IL" do
        @where  = "Chicago , IL"
        @object = Locality.search(@where)
        assert_equal @chicago, @object
      end
    end

    context "when its not a city" do
      should "not find 'River North, Chicago, IL" do
        @where  = "River North, Chicago, IL"
        @object = Locality.search(@where)
        assert_nil @object
      end

      should "not find '60610, IL'" do
        @where = "60610, IL"
        @object = Locality.search(@where)
        assert_nil @object
      end

      should "not find 'IL 60610'" do
        @where = "IL 60610"
        @object = Locality.search(@where)
        assert_nil @object
      end
    end

    context "when the city isn't in the database" do
      should "not find 'Hippyville, IL'" do
        @where = "Hippyville, IL"
        @object = Locality.search(@where)
        assert_nil @object
      end
    end
  end
end
