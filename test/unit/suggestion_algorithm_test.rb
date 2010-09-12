require 'test_helper'

class SuggestionAlgorithmTest < ActiveSupport::TestCase

  # turn off transactional fixtures here so we can test sphinx
  self.use_transactional_fixtures = false

  def setup
    @us               = Factory(:us)
    @il               = Factory(:il, :country => @us)
    @ny               = Factory(:ny, :country => @us)
    @ma               = Factory(:ma, :country => @us)
    @chicago          = Factory(:city, :name => 'Chicago', :state => @il, :timezone => Factory(:timezone_chicago), :lat => 41.850033, :lng => -87.6500523)
    @newyork          = Factory(:city, :name => 'New York', :state => @ny, :timezone => Factory(:timezone_chicago), :lat => 40.7143528, :lng => -74.0059731)
    @boston           = Factory(:city, :name => 'Boston', :state => @ma, :timezone => Factory(:timezone_chicago), :lat => 42.3584308, :lng => -71.0597732)
    # create locations
    @chicago_sbux     = Location.create(:name => "Chicago Starbucks", :country => @us, :city => @chicago)
    @chicago_lous     = Location.create(:name => "Chicago Lou Malnati's", :country => @us, :city => @chicago)
    @newyork_sbux     = Location.create(:name => "New York Starbucks", :country => @us, :city => @newyork)
    @boston_sbux      = Location.create(:name => "Boston Starbucks", :country => @us, :city => @boston)
    # create users
    @chicago_male1    = User.create(:name => "Chicago Male 1", :handle => 'chicago_male_1', :gender => 2, :city => @chicago)
    assert @chicago_male1.valid?
    @chicago_female1  = User.create(:name => "Chicago Female 1", :handle => 'chicago_female_1', :gender => 1, :city => @chicago)
    assert @chicago_female1.valid?
    @newyork_male1    = User.create(:name => "New York Male 1", :handle => 'newyork_male_1', :gender => 2, :city => @newyork)
    assert @newyork_male1.valid?
    @newyork_female1  = User.create(:name => "New York Female 1", :handle => 'newyork_female_1', :gender => 1, :city => @newyork)
    assert @newyork_female1.valid?
    @boston_male1     = User.create(:name => "Boston Male 1", :handle => 'boston_male_1', :gender => 2, :city => nil)
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
    Suggestion.delete_all
  end

  context "checkins, radius algorithm" do
    context "with only checkin matches" do
      setup do
        # create chicago checkins
        @chicago_male1.checkins.create(:location => @chicago_sbux, :checkin_at => 3.days.ago, :source_id => 'sbux', :source_type => 'foursquare')
        @chicago_female1.checkins.create(:location => @chicago_sbux, :checkin_at => 3.days.ago, :source_id => 'sbux', :source_type => 'foursquare')
      end
      
      should "create 1 suggestion with chicago female checkin match" do
        ThinkingSphinx::Test.run do
          ThinkingSphinx::Test.index 'user_core'
          @suggestions = SuggestionAlgorithm.create_for(@chicago_male1, :algorithm => [:checkins, :radius], :limit => 10)
          assert_equal 1, @suggestions.size
          assert_equal [[@chicago_male1, @chicago_female1]], @suggestions.collect(&:users)
          assert_equal ['checkin'], @suggestions.collect(&:match)
        end
      end
    end
    
    context "with checkin and radius matches" do
      setup do
        # create chicago checkins
        @chicago_male1.checkins.create(:location => @chicago_sbux, :checkin_at => 3.days.ago, :source_id => 'sbux', :source_type => 'foursquare')
        @chicago_female1.checkins.create(:location => @chicago_sbux, :checkin_at => 3.days.ago, :source_id => 'sbux', :source_type => 'foursquare')
        # create another chicago user
        @chicago_female2  = User.create(:name => "Chicago Female 2", :handle => 'chicago_female_2', :gender => 1, :city => @chicago)
      end

      should "create 1 suggestion with chicago female checkin and radius match" do
        ThinkingSphinx::Test.run do
          ThinkingSphinx::Test.index 'user_core'
          @suggestions = SuggestionAlgorithm.create_for(@chicago_male1, :algorithm => [:checkins, :radius], :limit => 10)
          assert_equal 2, @suggestions.size
          assert_equal [[@chicago_male1, @chicago_female1], [@chicago_male1, @chicago_female2]], @suggestions.collect(&:users)
          assert_equal ['checkin', 'radius'], @suggestions.collect(&:match)
        end
      end
    end
  end

  context "checkins, radius, gender algorithm" do
    context "with only gender matches" do
      setup do
        # create at least 1 boston checkin
        @boston_male1.checkins.create(:location => @boston_sbux, :checkin_at => 3.days.ago, :source_id => 'sbux', :source_type => 'foursquare')
      end

      should "create 2 suggestions with female users" do
        ThinkingSphinx::Test.run do
          ThinkingSphinx::Test.index 'user_core'
          @suggestions = SuggestionAlgorithm.create_for(@boston_male1, :algorithm => [:checkins, :radius, :gender], :limit => 10)
          assert_equal 2, @suggestions.size
          assert_equal [[@boston_male1, @chicago_female1], [@boston_male1, @newyork_female1]], @suggestions.collect(&:users)
          assert_equal ['gender', 'gender'], @suggestions.collect(&:match)
        end
      end
    end
  end

end