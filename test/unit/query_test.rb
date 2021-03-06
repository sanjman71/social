require 'test_helper'

class QueryTest < ActiveSupport::TestCase

  def setup
    @us         = countries(:us)
    @il         = states(:il)
    @chicago    = cities(:chicago)
  end

  context "search with" do
    setup do
      @attributes = Query.attributes(@il, @chicago, nil)
    end

    should "have hash attributes with :state_id" do
      assert_equal Hash[:state_id => @il.id, :city_id => @chicago.id], @attributes
    end
  end

  context "search query with a query string only" do
    setup do
      @hash = Query.build("hair salon")
    end

    should "have query hash" do
      assert_equal Hash[:query_raw => "hair salon", :query_and => "hair salon", :query_or => "hair | salon", :query_quorum => "\"hair salon\"/1"], 
                   @hash
    end
  end

  context "search query with attributes" do
    context "with tag_ids attribute" do
      setup do
        @hash = Query.build("tag_ids:131")
      end

      should "have attributes hash" do
        assert_equal Hash[:query_raw => "tag_ids:131", :query_and => '', :query_or => '', :query_quorum => '', :attributes => {:tag_ids => 131}], @hash
      end
    end
    
    context "with events attribute" do
      setup do
        @hash = Query.build("events:1")
      end

      should "have attributes hash" do
        assert_equal Hash[:query_raw => "events:1", :query_and => '', :query_or => '', :query_quorum => '', :attributes => {:events => 1..2**30}], @hash
      end
    end
    
    context "with no events attribute" do
      setup do
        @hash = Query.build("events:0")
      end

      should "have attributes hash" do
        assert_equal Hash[:query_raw => "events:0", :query_and => '', :query_or => '', :query_quorum => '', :attributes => {:events => 0}], @hash
      end
    end

    context "with popularity attribute" do
      setup do
        @hash = Query.build("popularity:50")
      end

      should "have attributes hash" do
        assert_equal Hash[:query_raw => "popularity:50", :query_and => '', :query_or => '', :query_quorum => '', 
                          :attributes => {:popularity => 50..2**30}], @hash
      end
    end
  end
  
  context "search query with fields" do
    context "with address field" do
      setup do
        @hash = Query.build("address:'200 grand'")
      end

      should "have fields hash" do
        assert_equal Hash[:query_raw => "address:'200 grand'", :query_and => '', :query_or => '', :query_quorum => '', 
                          :fields => {:address => '200 grand'}], @hash
      end
    end

    context "with address fields in caps" do
      setup do
        @hash = Query.build("address:'200 Grand Ave'")
      end

      should "have fields hash" do
        assert_equal Hash[:query_raw => "address:'200 Grand Ave'", :query_and => '', :query_or => '', :query_quorum => '', 
                          :fields => {:address => '200 Grand Ave'}], @hash
      end
    end
    
    context "with phone field" do
      context "with parens and hyphens" do
        setup do
          @hash = Query.build("phone:'(312) 555-1212'")
        end

        should "have fields hash" do
          assert_equal Hash[:query_raw => "phone:'(312) 555-1212'", :query_and => '', :query_or => '', :query_quorum => '', 
                            :fields => {:phone => '(312) 555-1212'}], @hash
        end
      end

      context "with dots" do
        setup do
          @hash = Query.build("phone:'312.555.1212'")
        end

        should "have fields hash" do
          assert_equal Hash[:query_raw => "phone:'312.555.1212'", :query_and => '', :query_or => '', :query_quorum => '', 
                            :fields => {:phone => '312.555.1212'}], @hash
        end
      end
    end
    
  end

  context "search query with a query string and events attribute" do
    setup do
      @hash = Query.build("music events:1")
    end
    
    should "have attributes hash" do
      assert_equal Hash[:query_raw => "music events:1", :query_and => 'music', :query_quorum => "\"music\"/1",
                        :query_or => 'music', :attributes => {:events => 1..2**30}], @hash
    end
  end
  
  context "search query with a query string and popularity attribute" do
    setup do
      @hash = Query.build("bar popularity:50")
    end
    
    should "have attributes hash" do
      assert_equal Hash[:query_raw => "bar popularity:50", :query_and => 'bar', :query_or => 'bar', :query_quorum => "\"bar\"/1",
                        :attributes => {:popularity => 50..2**30}], @hash
    end
  end
  
  context "search query with a query string and address field" do
    setup do
      @hash = Query.build("music address:'200 grand'")
    end
    
    should "have fields hash" do
      assert_equal Hash[:query_raw => "music address:'200 grand'", :query_and => 'music', :query_or => 'music', :query_quorum => "\"music\"/1",
                        :fields => {:address => '200 grand'}], @hash
    end
  end
  
  context "search query with a name field and address field" do
    setup do
      @hash = Query.build("name:'pizza' address:'200 grand'")
    end
    
    should "have fields hash" do
      assert_equal Hash[:query_raw => "name:'pizza' address:'200 grand'", :query_and => '', :query_or => '', :query_quorum => '',
                        :fields => {:name => 'pizza', :address => '200 grand'}], @hash
    end
  end
  
  context "search query with a query string, events attribute and address field" do
    setup do
      @hash = Query.build("music concerts events:1 address:'200 grand'")
    end
    
    should "have attributes and fields hash" do
      assert_equal Hash[:query_raw => "music concerts events:1 address:'200 grand'", :query_and => 'music concerts', 
                        :query_or => 'music | concerts', :query_quorum => "\"music concerts\"/1",
                        :attributes => {:events => 1..2**30}, :fields => {:address => '200 grand'}], @hash
    end
  end
  
  context "search locality attributes" do
    context "with country and state" do
      setup do
        @attributes = Query.attributes(@us, @il)
      end
    
      should "have attributes hash with country and state" do
        assert_equal Hash[:country_id => @us.id, :state_id => @il.id], @attributes
      end
    end

    context "with country, state, city, neighborhood" do
      setup do
        @river_north  = neighborhoods(:river_north)
        @attributes   = Query.attributes(@us, @il, @chicago, @river_north)
      end

      should "have attributes hash with country and state" do
        assert_equal Hash[:country_id => @us.id, :state_id => @il.id, :city_id => @chicago.id, :neighborhood_ids => @river_north.id], @attributes
      end
    end
  end

  context "search parse query" do
    context "with query 'coffee shop'" do
      setup do
        @hash = Query.build("coffee shop")
      end
      
      should "have different 'or' and 'and' queries" do
        assert_equal "coffee | shop", @hash[:query_or]
        assert_equal "coffee shop", @hash[:query_and]
      end
    end

    context "with query 'schuba's'" do
      setup do
        @hash = Query.build("schuba's")
      end

      should "have raw query with quote" do
        assert_equal "schuba's", @hash[:query_raw]
      end
      
      should "have query with quote removed" do
        assert_equal "schubas", @hash[:query_or]
      end
    end

    context "with query 'revive @ el ray'" do
      setup do
        @hash = Query.build("revive @ el ray")
      end

      should "have raw query with @" do
        assert_equal "revive @ el ray", @hash[:query_raw]
      end
      
      should "have query with @ removed" do
        assert_equal "revive | el | ray", @hash[:query_or]
      end
    end

    context "with query with quotes" do
      setup do
        @hash = Query.build("'dominos pizza'")
      end

      should "have raw query 'dominos pizza'" do
        assert_equal "'dominos pizza'", @hash[:query_raw]
      end

      should "have query with @ removed" do
        assert_equal Hash[:* => 'dominos pizza'], @hash[:fields]
      end
    end
    
    context "with query 'anything'" do
      setup do
        @hash = Query.build("anything")
      end
      
      should "have empty query" do
        assert_equal "", @hash[:query_or]
        assert_equal "", @hash[:query_and]
      end
      
      should "have raw query of 'anything'" do
        assert_equal "anything", @hash[:query_raw]
      end
    end
  end
  
  context "search normalize" do
    context "with quotes" do
      setup do
        @s = Query.normalize("'bar'")
      end
      
      should "remove quotes" do
        assert_equal 'bar', @s
      end
    end
    
    context "with dash" do
      setup do
        @s = Query.normalize("beer-bar")
      end
      
      should "remove quotes" do
        assert_equal 'beerbar', @s
      end
    end

    context "with @" do
      setup do
        @s = Query.normalize("beer@bar")
      end
      
      should "remove @" do
        assert_equal 'beerbar', @s
      end
    end

    context "with dashes" do
      setup do
        @s = Query.normalize("999-555-1212")
      end
      
      should "remove dashes" do
        assert_equal '9995551212', @s
      end
    end

    context "with dots" do
      setup do
        @s = Query.normalize("999.555.1212")
      end
      
      should "remove dots" do
        assert_equal '9995551212', @s
      end
    end
  end
  
  context "search remove fields" do
    context "empty string" do
      setup do
        @s = Query.remove_fields("")
      end
      
      should "not change query" do
        assert_equal '', @s
      end
    end

    context "with no field" do
      setup do
        @s = Query.remove_fields("beer")
      end
      
      should "not change query" do
        assert_equal 'beer', @s
      end
    end
    
    context "with field" do
      setup do
        @s = Query.remove_fields("tags:'hair salon'")
      end

      should "remove field" do
        assert_equal "'hair salon'", @s
      end
    end
  end
end