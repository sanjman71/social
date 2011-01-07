require 'test_helper'

class UserSearchTest < ActiveSupport::TestCase

  # turn off transactional fixtures here so we can test sphinx
  self.use_transactional_fixtures = false

  def setup
    @us               = Factory(:us)
    @il               = Factory(:il, :country => @us)
    @ny               = Factory(:ny, :country => @us)
    @ma               = Factory(:ma, :country => @us)
    @chicago          = Factory(:city, :name => 'Chicago', :state => @il, :lat => 41.850033, :lng => -87.6500523)
    @newyork          = Factory(:city, :name => 'New York', :state => @ny, :lat => 40.7143528, :lng => -74.0059731)
    @boston           = Factory(:city, :name => 'Boston', :state => @ma, :lat => 42.3584308, :lng => -71.0597732)
    # create locations
    @chicago_sbux     = Location.create!(:name => "Chicago Starbucks", :country => @us, :city => @chicago,
                                         :lat => 41.89248300, :lng => -87.6281306000)
    @chicago_coffee   = Location.create!(:name => "Chicago Coffee", :country => @us, :city => @chicago,
                                         :lat => 41.8840864000, :lng => -87.6412261000)
    @chicago_lous     = Location.create!(:name => "Chicago Lou Malnati's", :country => @us, :city => @chicago,
                                         :lat => 41.8903440000, :lng => -87.6337420000)
    @chicago_pizza    = Location.create!(:name => "Chicago Pizza", :country => @us, :city => @chicago,
                                         :lat => 41.8962000000, :lng => -87.6233000000)
    @newyork_sbux     = Location.create!(:name => "New York Starbucks", :country => @us, :city => @newyork,
                                         :lat => @newyork.lat, :lng => @newyork.lng)
    @boston_sbux      = Location.create!(:name => "Boston Starbucks", :country => @us, :city => @boston,
                                         :lat => @boston.lat, :lng => @boston.lng)
    @boston_coffee    = Location.create!(:name => "Boston Coffee", :country => @us, :city => @boston,
                                         :lat => @boston.lat, :lng => @boston.lng)
    # tag coffee places
    [@chicago_sbux, @chicago_coffee, @boston_sbux, @boston_coffee].each do |o|
      o.tag_list = ['cafe', 'coffee']
      o.save
    end
    # create users
    @chicago_male1    = User.create!(:name => "Chicago Male 1", :handle => 'chicago_male_1', :gender => 2,
                                     :member => 1, :city => @chicago)
    @chicago_male2    = User.create!(:name => "Chicago Male 2", :handle => 'chicago_male_2', :gender => 2,
                                     :member => 1, :city => @chicago)
    @chicago_female1  = User.create!(:name => "Chicago Female 1", :handle => 'chicago_female_1', :gender => 1,
                                     :member => 1, :city => @chicago)
    @chicago_female2  = User.create!(:name => "Chicago Female 2", :handle => 'chicago_female_2', :gender => 1,
                                     :member => 1, :city => @chicago)
    @chicago_female3  = User.create!(:name => "Chicago Female 3", :handle => 'chicago_female_3', :gender => 1,
                                     :member => 1, :city => @chicago)
    @newyork_male1    = User.create!(:name => "New York Male 1", :handle => 'newyork_male_1', :gender => 2,
                                     :member => 1, :city => @newyork)
    @newyork_female1  = User.create!(:name => "New York Female 1", :handle => 'newyork_female_1', :gender => 1,
                                     :member => 1, :city => @newyork)
    @boston_male1     = User.create!(:name => "Boston Male 1", :handle => 'boston_male_1', :gender => 2,
                                     :member => 1, :city => @boston)
    @boston_female1   = User.create!(:name => "Boston Female 1", :handle => 'boston_female_1', :gender => 1,
                                     :member => 1, :city => @boston)
  end

  def teardown
    [Checkin, CheckinLog, Location, Country, State, City, User].each { |o| o.delete_all }
  end

  def setup_checkins(checkin_at = nil)
    # create checkins
    @chi_checkin1 = @chicago_male1.checkins.create!(Factory.attributes_for(:foursquare_checkin,
                                                                           :location => @chicago_sbux,
                                                                           :checkin_at => checkin_at || Time.zone.now))
    @chi_checkin2 = @chicago_female1.checkins.create!(Factory.attributes_for(:foursquare_checkin,
                                                                             :location => @chicago_coffee,
                                                                             :checkin_at => checkin_at || Time.zone.now))
    @chi_checkin3 = @chicago_male2.checkins.create!(Factory.attributes_for(:foursquare_checkin,
                                                                           :location => @chicago_sbux,
                                                                           :checkin_at => checkin_at || Time.zone.now))
    @nyc_checkin1 = @newyork_female1.checkins.create!(Factory.attributes_for(:foursquare_checkin,
                                                                             :location => @newyork_sbux,
                                                                             :checkin_at => checkin_at || Time.zone.now))
    @chi_checkin4 = @chicago_male1.checkins.create!(Factory.attributes_for(:facebook_checkin,
                                                                           :location => @chicago_pizza,
                                                                           :checkin_at => checkin_at || Time.zone.now))
    # create locationships based on checkins
    @chicago_male1.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
    @chicago_female1.locationships.create!(:location => @chicago_coffee, :my_checkins => 1)
    @chicago_male2.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
    @newyork_female1.locationships.create!(:location => @newyork_sbux, :my_checkins => 1)
    @chicago_male1.locationships.create!(:location => @chicago_pizza, :my_checkins => 1)
  end

  context "search_all_checkins filter" do
    setup do
      setup_checkins
    end

    should "find 4 chicago checkins when user searching has no checkins" do
      @chicago_user1 = User.create!(:name => "Chicago User 1", :handle => 'chicago_user_1', :gender => 2,
                                    :member => 1, :city => @chicago)
      ThinkingSphinx::Test.run do
        @checkins = @chicago_user1.search_all_checkins(:miles => 50, :order => :sort_similar_locations)
        assert_equal 4, @checkins.size
        assert_equal [], [@chi_checkin1, @chi_checkin2, @chi_checkin3, @chi_checkin4] - @checkins.collect{ |o| o }
      end
    end

    should "find 4 chicago checkins filtered by distance, ordered by similar locations" do
      ThinkingSphinx::Test.run do
        @checkins = @chicago_male1.search_all_checkins(:miles => 50, :order => :sort_similar_locations)
        assert_equal 4, @checkins.size
        assert_equal [@chi_checkin1, @chi_checkin3, @chi_checkin4, @chi_checkin2], @checkins.collect{ |o| o }
        # assert_equal [:location, :location, :location, :tag], @checkins.collect{ |o| o.try(:matchby) }
        # assert_equal [8.0, 8.0, 5.0, 3.0], @checkins.collect(&:matchvalue)
      end
    end

    should "find 4 chicago checkins filtered by distance, ordered by similar locations + other checkins" do
      ThinkingSphinx::Test.run do
        @checkins = @chicago_male1.search_all_checkins(:miles => 50,
                                                       :order => [:sort_similar_locations, :sort_other_checkins])
        assert_equal 4, @checkins.size
        assert_equal [@chi_checkin3, @chi_checkin2, @chi_checkin1, @chi_checkin4], @checkins.collect{ |o| o }
      end
    end

    should "find 4 chicago checkins filtered by distance, weighted by users that are not @chicago_male1" do
      ThinkingSphinx::Test.run do
        @checkins = @chicago_male1.search_all_checkins(:miles => 50,
                                                       :order => {:sort_unweight_users => [@chicago_male1.id]})
        assert_equal 4, @checkins.size
        assert_equal [@chi_checkin2, @chi_checkin3, @chi_checkin1, @chi_checkin4], @checkins.collect{ |o| o }
      end
    end

    should "find 4 chicago checkins filtered by distance, weighted by users that are @chicago_male1" do
      ThinkingSphinx::Test.run do
        @checkins = @chicago_male1.search_all_checkins(:miles => 50,
                                                       :order => [:sort_weight_users => [@chicago_male1.id]])
        assert_equal 4, @checkins.size
        assert_equal [@chi_checkin1, @chi_checkin4, @chi_checkin2, @chi_checkin3], @checkins.collect{ |o| o }
      end
    end

    should "find all 5 checkins, ordered by distance" do
      ThinkingSphinx::Test.run do
        @checkins = @chicago_male1.search_all_checkins(:miles => 1000, :order => :sort_closer_locations)
        assert_equal 5, @checkins.size
        # chicago checkins first
        assert_equal [@chi_checkin1, @chi_checkin2, @chi_checkin3, @chi_checkin4, @nyc_checkin1], @checkins.collect{ |o| o }
      end
    end

    should "find all 5 checkins, using similar locations, other checkins, distance sort oder" do
      ThinkingSphinx::Test.run do
        @checkins = @chicago_male1.search_all_checkins(:miles => 1000,
                                                       :order => [:sort_similar_locations, :sort_other_checkins, :sort_closer_locations])
        assert_equal 5, @checkins.size
        # chicago checkins first
        assert_equal [@chi_checkin3, @chi_checkin2, @chi_checkin1, @chi_checkin4, @nyc_checkin1], @checkins.collect{ |o| o }
      end
    end
    
    should "find 4 checkins filtered/grouped by user" do
      ThinkingSphinx::Test.run do
        @checkins = @chicago_male1.search_all_checkins(:miles => 1000,
                                                       :order => [:sort_similar_locations, :sort_other_checkins, :sort_closer_locations],
                                                       :group => :user)
        assert_equal 4, @checkins.size
        # chicago checkins first
        assert_equal [@chi_checkin3, @chi_checkin2, @chi_checkin1, @nyc_checkin1], @checkins.collect{ |o| o }
      end
    end
  end

  context "search_others_checkins filter" do
    setup do
      setup_checkins
    end

    should "find 2 checkins filtered by distance, ordered by similar locations" do
      ThinkingSphinx::Test.run do
        @checkins = @chicago_male1.search_others_checkins(:miles => 50,
                                                          :order => :sort_similar_locations)
        assert_equal 2, @checkins.size
        assert_equal [@chi_checkin3, @chi_checkin2], @checkins.collect{ |o| o }
      end
    end
  end

  context "search_friends_checkins filter" do
    setup do
      setup_checkins
      # add friends
      @chicago_male1.friendships.create!(:friend => @chicago_female1)
      @chicago_male1.friendships.create!(:friend => @chicago_male2)
    end

    should "find 2 checkins by friends, filtered by distance, ordered by similar locations" do
      ThinkingSphinx::Test.run do
        @checkins = @chicago_male1.search_friends_checkins(:miles => 50,
                                                           :order => :sort_similar_locations)
        assert_equal 2, @checkins.size
        assert_equal [@chi_checkin3, @chi_checkin2], @checkins.collect{ |o| o }
      end
    end
  end

  context "search_daters_checkins filter" do
    setup do
      setup_checkins
    end

    should "find 1 checkin by a female, filtered by distance, ordered by similar locations" do
      ThinkingSphinx::Test.run do
        @checkins = @chicago_male1.search_daters_checkins(:miles => 50,
                                                          :order => :sort_similar_locations)
        assert_equal 1, @checkins.size
        assert_equal [@chi_checkin2], @checkins.collect{ |o| o }
      end
    end
    
    should "find 0 checkins by a female, filtered by distance, ordered by similar locations" do
      # add female as friend, which should exclude her as a dater
      @chicago_male1.friendships.create!(:friend => @chicago_female1)
      ThinkingSphinx::Test.run do
        @checkins = @chicago_male1.search_daters_checkins(:miles => 50,
                                                          :order => :sort_similar_locations)
        assert_equal 0, @checkins.size
      end
    end
  end

  context "search_today_checkins filter" do
    setup do
      # add checkins 3 days ago
      setup_checkins(3.days.ago)
    end

    should "find 1 checkin in the past 24 hours" do
      # mark checkin timestamp within the last day
      @chi_checkin2.update_attribute(:checkin_at, 23.hours.ago)
      ThinkingSphinx::Test.run do
        @checkins = @chicago_male1.search_today_checkins
        assert_equal 1, @checkins.size
        assert_equal [@chi_checkin2], @checkins.collect{ |o| o }
      end
    end

    should "find 0 checkins in the past 24 hours" do
      # mark checkin timestamp at just more than 1 day ago
      @chi_checkin2.update_attribute(:checkin_at, 25.hours.ago)
      ThinkingSphinx::Test.run do
        @checkins = @chicago_male1.search_today_checkins
        assert_equal 0, @checkins.size
      end
    end
  end

  context "sort checkins by date" do
    should "rank past day's checkins higher than older checkins" do
      @chi_checkin1 = @chicago_male1.checkins.create!(Factory.attributes_for(:foursquare_checkin,
                                                                             :location => @chicago_sbux,
                                                                             :checkin_at => 25.hours.ago))
      @chi_checkin2 = @chicago_male1.checkins.create!(Factory.attributes_for(:foursquare_checkin,
                                                                             :location => @chicago_sbux,
                                                                             :checkin_at => 3.hours.ago))
      ThinkingSphinx::Test.run do
        @checkins = @chicago_male1.search_all_checkins(:order => [:sort_checkins_past_day])
        assert_equal 2, @checkins.size
        assert_equal [@chi_checkin2, @chi_checkin1], @checkins.collect{ |o| o }
      end
    end

    should "rank past week's checkins higher than older checkins" do
      @chi_checkin1 = @chicago_male1.checkins.create!(Factory.attributes_for(:foursquare_checkin,
                                                                             :location => @chicago_sbux,
                                                                             :checkin_at => 10.days.ago))
      @chi_checkin2 = @chicago_male1.checkins.create!(Factory.attributes_for(:foursquare_checkin,
                                                                             :location => @chicago_sbux,
                                                                             :checkin_at => 3.days.ago))
      ThinkingSphinx::Test.run do
        @checkins = @chicago_male1.search_all_checkins(:order => [:sort_checkins_past_week])
        assert_equal 2, @checkins.size
        assert_equal [@chi_checkin2, @chi_checkin1], @checkins.collect{ |o| o }
      end
    end
  end

  # context "search_now_checkins filter" do
  #   setup do
  #     setup_checkins
  #   end
  #   
  #   should "find 1 user marked as available now" do
  #     # mark 1 user as available now, all their checkins will be marked as well
  #     @chicago_female1.availability_attributes = {:now => 1}
  #     @chicago_female1.save
  #     ThinkingSphinx::Test.run do
  #       @checkins = @chicago_male1.search_now_checkins
  #       assert_equal 1, @checkins.size
  #       assert_equal [@chi_checkin2], @checkins.collect{ |o| o }
  #     end
  #   end
  # end

  context "search_all_todos filter" do
    setup do
      # create planned checkin
      @pcheckin1 = @chicago_male1.planned_checkins.create!(:location => @chicago_coffee)
      work_off_delayed_jobs
    end

    should "find 1 todos" do
      ThinkingSphinx::Test.run do
        @todos = @chicago_male1.search_all_todos
        assert_equal 1, @todos.size
        assert_equal [@pcheckin1], @todos.collect{ |o| o }
      end
    end
  end

  context "search_daters_by_checkins filter" do
    setup do
      # 3 female chicago users + 1 boston female user checkins at different locations
      @chicago_female1.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
      @chicago_female2.locationships.create!(:location => @chicago_coffee, :my_checkins => 1)
      @chicago_female3.locationships.create!(:location => @chicago_pizza, :my_checkins => 1)
      @boston_female1.locationships.create!(:location => @boston_coffee, :my_checkins => 1)
      # chicago searcher has 1 checkin location, 1 todo location in common
      @chicago_male1.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
      @chicago_male1.locationships.create!(:location => @chicago_coffee, :todo_checkins => 1)
      @chicago_male1.locationships.create!(:location => @chicago_pizza, :friend_checkins => 1)
    end

    should "find 3 daters filtered by checkin locations, ordered by similar locations" do
      ThinkingSphinx::Test.run do
        @users = @chicago_male1.search_daters_by_checkins(:order => :sort_similar_locations)
        assert_equal 3, @users.size
        assert_equal [@chicago_female1, @chicago_female2, @chicago_female3], @users.collect{ |o| o }
      end
    end
  end

  # deprecated: no search by locations tags for now
  # context "search_locations_by_tags filter" do
  #   should "find 0 locations with same tags when user has no checkin location tags" do
  #     ThinkingSphinx::Test.run do
  #       @locations = @chicago_male1.search_locations_by_tags
  #       assert_equal 0, @locations.size
  #     end
  #   end
  # 
  #   should "find 3 locations with same tags when user has checkin location tags" do
  #     @chicago_male1.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
  #     ThinkingSphinx::Test.run do
  #       @locations = @chicago_male1.search_locations_by_tags
  #       assert_equal 3, @locations.size
  #       assert_equal [@chicago_coffee, @boston_sbux, @boston_coffee], @locations.collect{ |o| o }
  #     end
  #   end
  # end

  context "search_friends filter" do
    setup do
      @chicago_male1.friendships.create!(:friend => @chicago_female1)
      @chicago_male1.friendships.create!(:friend => @chicago_male2)
    end

    should "find 2 users filtered by friends" do
      ThinkingSphinx::Test.run do
        @users = @chicago_male1.search_friends(:miles => 10)
        assert_equal 2, @users.size
        assert_equal [@chicago_female1, @chicago_male2], @users.collect{ |o| o }
      end
    end
  end

  context "search_friends_by_checkins filter" do
    setup do
      # 2 female chicago users + 1 chicago male user checkin to different locations
      @chicago_female1.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
      @chicago_female2.locationships.create!(:location => @chicago_coffee, :my_checkins => 1)
      @chicago_male2.locationships.create!(:location => @chicago_pizza, :my_checkins => 1)
      # chicago searcher has 2 friend checkin location
      @chicago_male1.locationships.create!(:location => @chicago_sbux, :friend_checkins => 1)
      @chicago_male1.locationships.create!(:location => @chicago_pizza, :friend_checkins => 1)
    end
  
    should "find 2 users filtered by friend checkins" do
      ThinkingSphinx::Test.run do
        @users = @chicago_male1.search_friends_by_checkins
        assert_equal 2, @users.size
        assert_equal [@chicago_male2, @chicago_female1], @users.collect{ |o| o }
      end
    end
  end

  context "search_users_by_checkins filter" do
    setup do
      @chicago_female1.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
      @chicago_male2.locationships.create!(:location => @chicago_pizza, :my_checkins => 1)
      # chicago searcher has 2 checkin locations, 2 common locations with other users
      @chicago_male1.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
      @chicago_male1.locationships.create!(:location => @chicago_pizza, :my_checkins => 1)
    end

    should "find 2 users filtered by common checkins" do
      ThinkingSphinx::Test.run do
        @users = @chicago_male1.search_users_by_checkins
        assert_equal 2, @users.size
        assert_equal [@chicago_male2, @chicago_female1], @users.collect{ |o| o }
      end
    end
  end

  context "search_daters filter" do
    setup do
      # 3 female chicago users + 1 boston female user checkin to different locations
      @chicago_female1.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
      @chicago_female2.locationships.create!(:location => @chicago_coffee, :my_checkins => 1)
      @chicago_female3.locationships.create!(:location => @chicago_pizza, :my_checkins => 1)
      @boston_female1.locationships.create!(:location => @boston_coffee, :my_checkins => 1)
      # chicago searcher has 1 checkin location in common
      @chicago_male1.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
    end

    should "find 3 users filtered by distance, ordered by similar locations" do
      ThinkingSphinx::Test.run do
        @users = @chicago_male1.search_daters(:miles => 10, :order => :sort_similar_locations)
        assert_equal 3, @users.size
        assert_equal [@chicago_female1, @chicago_female2, @chicago_female3], @users.collect{ |o| o }
      end
    end

    should "find 3 users filtered by distance, ordered by relevance" do
      ThinkingSphinx::Test.run do
        @users = @chicago_male1.search_daters(:miles => 10)
        assert_equal 3, @users.size
        assert_equal [@chicago_female1, @chicago_female2, @chicago_female3], @users.collect{ |o| o }.sort_by(&:id)
      end
    end
  end

  context "search_locations filter" do
    setup do
      # 3 female chicago users + 1 boston female user checkin to different locations
      @chicago_female1.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
      @chicago_female2.locationships.create!(:location => @chicago_coffee, :my_checkins => 1)
      @chicago_female3.locationships.create!(:location => @chicago_pizza, :my_checkins => 1)
      @boston_female1.locationships.create!(:location => @boston_coffee, :my_checkins => 1)
      # chicago searcher has 1 checkin location in common
      @chicago_male1.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
    end
    
    should "find 3 locations filtered by distance, ordered by relevance" do
      ThinkingSphinx::Test.run do
        @locations = @chicago_male1.search_locations(:miles => 10, :klass => Location)
        assert_equal 3, @locations.size
        assert_equal [@chicago_coffee, @chicago_lous, @chicago_pizza], @locations.collect{ |o| o }.sort_by(&:id)
        assert_equal [:geo_filter, :geo_filter, :geo_filter], @locations.collect(&:matchby)
        assert_equal [0.0, 0.0, 0.0], @locations.collect(&:matchvalue)
        assert_equal [1, 1, 1], @locations.results[:matches].collect{ |o| o[:weight] }
      end
    end
  end

  context "search_gender filter" do
    should "find 3 female users filtered by distance and default gender" do
      ThinkingSphinx::Test.run do
        @users = @chicago_male1.search_gender(:miles => 10)
        assert_equal 3, @users.size
      end
    end

    should "find 1 male user filtered by distance and males" do
      ThinkingSphinx::Test.run do
        @users = @chicago_male1.search_gender(:miles => 10, :with_gender => 2)
        assert_equal 1, @users.size
      end
    end

    should "find 5 female users filtered by default gender" do
      ThinkingSphinx::Test.run do
        @users = @chicago_male1.search_gender
        assert_equal 5, @users.size
      end
    end

    should "find 3 male users filtered by males" do
      ThinkingSphinx::Test.run do
        @users = @chicago_male1.search_gender(:with_gender => 2)
        assert_equal 3, @users.size
      end
    end
  end

end