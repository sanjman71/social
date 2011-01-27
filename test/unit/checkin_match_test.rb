require 'test_helper'

class CheckinMatchTest < ActiveSupport::TestCase

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
    @chicago_lavazza  = Location.create!(:name => "Chicago Lavazza", :country => @us, :city => @chicago,
                                         :lat => 41.8840864000, :lng => -87.6412261000)

    # create users
    @chicago_male1    = Factory.create(:user, :handle => 'chicago_male_1', :gender => 2, :member => 1,
                                       :city => @chicago)
    @chicago_male2    = Factory.create(:user, :handle => 'chicago_male_2', :gender => 2, :member => 1,
                                       :city => @chicago)
    @chicago_female1  = Factory.create(:user, :handle => 'chicago_female_1', :gender => 1, :member => 1,
                                       :city => @chicago)
    @chicago_female2  = Factory.create(:user, :handle => 'chicago_female_2', :gender => 1, :member => 0,
                                       :city => @chicago)
    # tag coffee locations
    [@chicago_sbux, @chicago_coffee, @chicago_lavazza].each do |o|
      o.tag_list = ['cafe', 'coffee']
      o.save
    end
    
  end

  def teardown
    DatabaseCleaner.clean
  end

  context "match strategy exact" do
    setup do
      # create checkins at same place
      @chi_checkin1 = @chicago_male1.checkins.create!(Factory.attributes_for(:foursquare_checkin,
                                                                             :location => @chicago_sbux))
      @chi_checkin2 = @chicago_female1.checkins.create!(Factory.attributes_for(:foursquare_checkin,
                                                                               :location => @chicago_sbux))
      @chi_checkin3 = @chicago_male2.checkins.create!(Factory.attributes_for(:foursquare_checkin,
                                                                             :location => @chicago_sbux))
    end

    should "find 1 dater match" do
      ThinkingSphinx::Test.run do
        @matches = @chi_checkin1.match_exact
        assert_equal 1, ([@chi_checkin2.id].to_set & @matches.collect(&:id).to_set).size
      end
    end

    should "find 2 dater matches, and include non-members" do
      # create non-member checkin
      @chi_checkin4 = @chicago_female2.checkins.create!(Factory.attributes_for(:foursquare_checkin,
                                                                               :location => @chicago_sbux))
      ThinkingSphinx::Test.run do
        @matches = @chi_checkin1.match_exact
        assert_equal 2, ([@chi_checkin2.id, @chi_checkin4.id].to_set & @matches.collect(&:id).to_set).size
      end
    end
  end

  context "match strategy similar" do
    setup do
      # create checkins at similar places
      @chi_checkin1 = @chicago_male1.checkins.create!(Factory.attributes_for(:foursquare_checkin,
                                                                             :location => @chicago_sbux))
      @chi_checkin2 = @chicago_female1.checkins.create!(Factory.attributes_for(:foursquare_checkin,
                                                                               :location => @chicago_coffee))
      @chi_checkin3 = @chicago_male2.checkins.create!(Factory.attributes_for(:foursquare_checkin,
                                                                             :location => @chicago_coffee))
    end

    should "find 1 dater match" do
      ThinkingSphinx::Test.run do
        @matches = @chi_checkin1.match_similar
        assert_equal 1, ([@chi_checkin2.id].to_set & @matches.collect(&:id).to_set).size
      end
    end

    should "find 2 dater matches, and include non-members" do
      # create non-member checkin at similar location
      @chi_checkin4 = @chicago_female2.checkins.create!(Factory.attributes_for(:foursquare_checkin,
                                                                               :location => @chicago_lavazza))
      ThinkingSphinx::Test.run do
        @matches = @chi_checkin1.match_similar
        assert_equal 2, ([@chi_checkin2.id, @chi_checkin4.id].to_set & @matches.collect(&:id).to_set).size
      end
    end
  end
end