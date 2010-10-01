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
    @chicago_sbux     = Location.create(:name => "Chicago Starbucks", :country => @us, :city => @chicago)
    @chicago_coffee   = Location.create(:name => "Chicago Coffee", :country => @us, :city => @chicago)
    @chicago_lous     = Location.create(:name => "Chicago Lou Malnati's", :country => @us, :city => @chicago)
    @chicago_pizza    = Location.create(:name => "Chicago Pizza", :country => @us, :city => @chicago)
    @newyork_sbux     = Location.create(:name => "New York Starbucks", :country => @us, :city => @newyork)
    @boston_sbux      = Location.create(:name => "Boston Starbucks", :country => @us, :city => @boston)
    @boston_coffee    = Location.create(:name => "Boston Coffee", :country => @us, :city => @boston)
    # tag coffee places
    [@chicago_sbux, @chicago_coffee, @boston_sbux, @boston_coffee].each do |o|
      o.tag_list = ['cafe', 'coffee']
      o.save
    end
    # create users
    @chicago_male1    = User.create(:name => "Chicago Male 1", :handle => 'chicago_male_1', :gender => 2, :city => @chicago)
    assert @chicago_male1.valid?
    @chicago_female1  = User.create(:name => "Chicago Female 1", :handle => 'chicago_female_1', :gender => 1, :city => @chicago)
    assert @chicago_female1.valid?
    @chicago_female2  = User.create(:name => "Chicago Female 2", :handle => 'chicago_female_2', :gender => 1, :city => @chicago)
    assert @chicago_female2.valid?
    @chicago_female3  = User.create(:name => "Chicago Female 3", :handle => 'chicago_female_3', :gender => 1, :city => @chicago)
    assert @chicago_female3.valid?
    @newyork_male1    = User.create(:name => "New York Male 1", :handle => 'newyork_male_1', :gender => 2, :city => @newyork)
    assert @newyork_male1.valid?
    @newyork_female1  = User.create(:name => "New York Female 1", :handle => 'newyork_female_1', :gender => 1, :city => @newyork)
    assert @newyork_female1.valid?
    @boston_male1     = User.create(:name => "Boston Male 1", :handle => 'boston_male_1', :gender => 2, :city => @boston)
    assert @boston_male1.valid?
    @boston_female1   = User.create(:name => "Boston Female 1", :handle => 'boston_female_1', :gender => 1, :city => @boston)
    assert @boston_male1.valid?
  end

  def teardown
    Country.delete_all
    State.delete_all
    City.delete_all
    User.delete_all
    Location.delete_all
    Checkin.delete_all
    CheckinLog.delete_all
  end

  context "geo search" do
    setup do
      # create chicago and boston checkins
      @chicago_male1.checkins.create(:location => @chicago_sbux, :checkin_at => 3.days.ago, :source_id => 'sbux', :source_type => 'foursquare')
      @chicago_female1.checkins.create(:location => @chicago_sbux, :checkin_at => 3.days.ago, :source_id => 'sbux', :source_type => 'foursquare')
      @chicago_female2.checkins.create(:location => @chicago_coffee, :checkin_at => 3.days.ago, :source_id => 'coffee', :source_type => 'foursquare')
      @chicago_female3.checkins.create(:location => @chicago_pizza, :checkin_at => 3.days.ago, :source_id => 'pizza', :source_type => 'foursquare')
      @boston_female1.checkins.create(:location => @boston_coffee, :checkin_at => 3.days.ago, :source_id => 'coffee', :source_type => 'foursquare')
    end

    context "order by checkins, tags" do
      should "find 2 geo coffee matches, order by checkin, then tags, then geo" do
        ThinkingSphinx::Test.run do
          ThinkingSphinx::Test.index 'user_core'
          @users = @chicago_male1.search_geo(:miles => 10, :order => :checkins_tags)
          assert_equal 3, @users.size
          assert_equal [@chicago_female1, @chicago_female2, @chicago_female3], @users.collect{ |o| o }
          assert_equal [8.0, 3.0, 0.0], @users.results[:matches].collect{ |o| o[:attributes]["@expr"] }
          assert_equal [:checkin, :tag, :geo], @users.collect(&:matchie)
        end
      end
    end

    context "order by geodist, relevance" do
      should "find 3 geo coffee matches" do
        ThinkingSphinx::Test.run do
          ThinkingSphinx::Test.index 'user_core'
          @users = @chicago_male1.search_geo(:miles => 10)
          assert_equal 3, @users.size
          assert_equal [@chicago_female1, @chicago_female2, @chicago_female3], @users.collect{ |o| o }.sort_by(&:id)
          assert_equal [nil, nil, nil], @users.results[:matches].collect{ |o| o[:attributes]["@expr"] }
          assert_equal [1, 1, 1], @users.results[:matches].collect{ |o| o[:weight] }
          assert_equal [:geo, :geo, :geo], @users.collect(&:matchie)
        end
      end
    end
  end

end