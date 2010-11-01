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
    @chicago_sbux     = Location.create!(:name => "Chicago Starbucks", :country => @us, :city => @chicago)
    @chicago_coffee   = Location.create!(:name => "Chicago Coffee", :country => @us, :city => @chicago)
    @chicago_lous     = Location.create!(:name => "Chicago Lou Malnati's", :country => @us, :city => @chicago)
    @chicago_pizza    = Location.create!(:name => "Chicago Pizza", :country => @us, :city => @chicago)
    @newyork_sbux     = Location.create!(:name => "New York Starbucks", :country => @us, :city => @newyork)
    @boston_sbux      = Location.create!(:name => "Boston Starbucks", :country => @us, :city => @boston)
    @boston_coffee    = Location.create!(:name => "Boston Coffee", :country => @us, :city => @boston)
    # tag coffee places
    [@chicago_sbux, @chicago_coffee, @boston_sbux, @boston_coffee].each do |o|
      o.tag_list = ['cafe', 'coffee']
      o.save
    end
    # create users
    @chicago_male1    = User.create!(:name => "Chicago Male 1", :handle => 'chicago_male_1', :gender => 2,
                                     :city => @chicago)
    @chicago_female1  = User.create!(:name => "Chicago Female 1", :handle => 'chicago_female_1', :gender => 1,
                                     :city => @chicago)
    @chicago_female2  = User.create!(:name => "Chicago Female 2", :handle => 'chicago_female_2', :gender => 1,
                                     :city => @chicago)
    @chicago_female3  = User.create!(:name => "Chicago Female 3", :handle => 'chicago_female_3', :gender => 1,
                                     :city => @chicago)
    @newyork_male1    = User.create!(:name => "New York Male 1", :handle => 'newyork_male_1', :gender => 2,
                                     :city => @newyork)
    @newyork_female1  = User.create!(:name => "New York Female 1", :handle => 'newyork_female_1', :gender => 1,
                                     :city => @newyork)
    @boston_male1     = User.create!(:name => "Boston Male 1", :handle => 'boston_male_1', :gender => 2,
                                     :city => @boston)
    @boston_female1   = User.create!(:name => "Boston Female 1", :handle => 'boston_female_1', :gender => 1,
                                     :city => @boston)
  end

  def teardown
    [Checkin, CheckinLog, Location, Country, State, City, User].each { |o| o.delete_all }
  end

  context "checkin search filter" do
    setup do
      # 3 female chicago users + 1 boston female user checkin to different locations
      @chicago_female1.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
      @chicago_female2.locationships.create!(:location => @chicago_coffee, :my_checkins => 1)
      @chicago_female3.locationships.create!(:location => @chicago_pizza, :my_checkins => 1)
      @boston_female1.locationships.create!(:location => @boston_coffee, :my_checkins => 1)
      # chicago searcher has 1 checkin location and 1 planned location in common
      @chicago_male1.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
      @chicago_male1.locationships.create!(:location => @chicago_coffee, :planned_checkins => 1)
    end

    should "find 2 matches when filtering by checkins, order by my checkins, then planned checkins" do
      ThinkingSphinx::Test.run do
        ThinkingSphinx::Test.index 'user_core'
        sleep(0.25)
        @users = @chicago_male1.search_checkins(:order => :checkins)
        assert_equal 2, @users.size
        assert_equal [@chicago_female1, @chicago_female2], @users.collect{ |o| o }
        assert_equal [:checkin, :checkin], @users.collect(&:matchby)
        assert_equal [5.0, 3.0], @users.collect(&:matchiness)
      end
    end
  end

  context "geo search filter" do
    setup do
      # 3 female chicago users + 1 boston female user checkin to different locations
      @chicago_female1.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
      @chicago_female2.locationships.create!(:location => @chicago_coffee, :my_checkins => 1)
      @chicago_female3.locationships.create!(:location => @chicago_pizza, :my_checkins => 1)
      @boston_female1.locationships.create!(:location => @boston_coffee, :my_checkins => 1)
      # chicago searcher has 1 checkin location in common
      @chicago_male1.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
    end

    should "find 3 matches, order by checkin, then tags, then geo" do
      ThinkingSphinx::Test.run do
        ThinkingSphinx::Test.index 'user_core'
        sleep(0.25)
        @users = @chicago_male1.search_geo(:miles => 10, :order => :checkins_tags)
        assert_equal 3, @users.size
        assert_equal [@chicago_female1, @chicago_female2, @chicago_female3], @users.collect{ |o| o }
        assert_equal [:checkin, :tag, :geo], @users.collect(&:matchby)
        assert_equal [8.0, 3.0, 0.0], @users.collect(&:matchiness)
      end
    end

    should "find 3 geo coffee matches with relevance ordering" do
      ThinkingSphinx::Test.run do
        ThinkingSphinx::Test.index 'user_core'
        sleep(0.25)
        @users = @chicago_male1.search_geo(:miles => 10)
        assert_equal 3, @users.size
        assert_equal [@chicago_female1, @chicago_female2, @chicago_female3], @users.collect{ |o| o }.sort_by(&:id)
        assert_equal [:geo, :geo, :geo], @users.collect(&:matchby)
        assert_equal [0.0, 0.0, 0.0], @users.collect(&:matchiness)
        assert_equal [1, 1, 1], @users.results[:matches].collect{ |o| o[:weight] }
      end
    end
  end

end