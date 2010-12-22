require 'test_helper'

class SuggestionFactoryTest < ActiveSupport::TestCase

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
                                         :lat => 41.850033, :lng => -87.6500523)
    @chicago_coffee   = Location.create!(:name => "Chicago Coffee", :country => @us, :city => @chicago,
                                         :lat => 41.850033, :lng => -87.6500523)
    @chicago_lous     = Location.create!(:name => "Chicago Lou Malnati's", :country => @us, :city => @chicago,
                                         :lat => 41.850033, :lng => -87.6500523)
    @chicago_pizza    = Location.create!(:name => "Chicago Pizza", :country => @us, :city => @chicago,
                                         :lat => 41.850033, :lng => -87.6500523)
    @newyork_sbux     = Location.create!(:name => "New York Starbucks", :country => @us, :city => @newyork,
                                         :lat => 40.7143528, :lng => -74.0059731)
    @boston_sbux      = Location.create!(:name => "Boston Starbucks", :country => @us, :city => @boston,
                                         :lat => 42.3584308, :lng => -71.0597732)
    @boston_coffee    = Location.create!(:name => "Boston Coffee", :country => @us, :city => @boston,
                                         :lat => 42.3584308, :lng => -71.0597732)
    # tag coffee places
    [@chicago_sbux, @chicago_coffee, @boston_sbux, @boston_coffee].each do |o|
      o.tag_list = ['cafe', 'coffee']
      o.save
    end
  end

  def setup_chicago_users
    setup_chicago_female_users
    setup_chicago_male_users
  end

  def setup_chicago_female_users
    @chicago_female1  = User.create!(:name => "Chicago Female 1", :handle => 'chicago_female_1', :gender => 1,
                                     :member => 1, :city => @chicago, :lat => 41.850033, :lng => -87.6500523)
  end

  def setup_chicago_male_users
    @chicago_male1    = User.create!(:name => "Chicago Male 1", :handle => 'chicago_male_1', :gender => 2,
                                     :member => 1, :city => @chicago, :lat => 41.850033, :lng => -87.6500523)
  end

  def setup_ny_users
    @newyork_male1    = User.create!(:name => "New York Male 1", :handle => 'newyork_male_1', :gender => 2,
                                     :member => 1, :city => @newyork, :lat => 40.7143528, :lng => -74.0059731)
    @newyork_female1  = User.create!(:name => "New York Female 1", :handle => 'newyork_female_1', :gender => 1,
                                     :member => 1, :city => @newyork, :lat => 40.7143528, :lng => -74.0059731)
  end

  def setup_boston_users
    @boston_male1     = User.create!(:name => "Boston Male 1", :handle => 'boston_male_1', :gender => 2,
                                     :member => 1, :city => @boston, :lat => 42.3584308, :lng => -71.0597732)
    @boston_female1   = User.create!(:name => "Boston Female 1", :handle => 'boston_female_1', :gender => 1,
                                     :member => 1, :city => @boston, :lat => 42.3584308, :lng => -71.0597732)
  end

  def teardown
    [Suggestion, Checkin, CheckinLog, Location, Locationship, Country, State, City, User, Delayed::Job].each { |o| o.delete_all }
  end

  context "geo based algorithm" do
    setup do
      @algorithm = [:geo_checkins, :geo_tags, :geo]
    end

    should "not create suggestions with non-member users" do
      setup_chicago_users
      # make sure other chicago users are non-members
      @chicago_female1.update_attribute(:member, 0)
      ThinkingSphinx::Test.run do
        @suggestions = SuggestionFactory.create(:user_id => @chicago_male1.id, :algorithm => @algorithm,
                                                :limit => 10)
      end
      assert_equal 0, @suggestions.size
    end

    should "not create suggestions with friends" do
      setup_chicago_users
      # add chicago user locationships and a friend
      @chicago_male1.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
      @chicago_female1.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
      @chicago_male1.friendships.create!(:friend => @chicago_female1)
      ThinkingSphinx::Test.run do
        @suggestions = SuggestionFactory.create(:user_id => @chicago_male1.id,
                                                :algorithm => @algorithm, :limit => 10)
      end
      assert_equal 0, @suggestions.size
    end

    should "not create suggestions with checkins from users outside of home radius" do
      setup_chicago_male_users
      setup_boston_users
      # add chicago and boston user checkins to the same place
      @chicago_male1.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
      @boston_female1.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
      ThinkingSphinx::Test.run do
        @suggestions = SuggestionFactory.create(:user_id => @chicago_male1.id, :algorithm => @algorithm,
                                                :limit => 10)
      end
      assert_equal 0, @suggestions.size
    end
    
    should "not create suggestions with common user tags outside of home radius" do
      setup_chicago_male_users
      setup_ny_users
      # add chicago and new york users with similar tags
      @chicago_male1.tag_ids = @newyork_female1.tag_ids = @chicago_sbux.tag_ids
      @chicago_male1.save
      @newyork_female1.save
      ThinkingSphinx::Test.run do
        @suggestions = SuggestionFactory.create(:user_id => @chicago_male1.id, :algorithm => @algorithm,
                                                :limit => 10)
      end
      assert_equal 0, @suggestions.size
    end
    
    should "create suggestion with local daters" do
      setup_chicago_users
      ThinkingSphinx::Test.run do
        @suggestions = SuggestionFactory.create(:user_id => @chicago_male1.id, :algorithm => @algorithm,
                                                :limit => 10)
      end
      assert_equal 1, @suggestions.size
      assert_equal [[@chicago_male1.id, @chicago_female1.id].sort].flatten, @suggestions.map{ |s| [s.users.collect(&:id).sort]}.flatten
      assert_equal ['geo'], @suggestions.collect(&:match)
    end
  end

  # context "geo checkins, geo algorithm" do
  #   setup do
  #     # add chicago user locationships
  #     @chicago_male1.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
  #     @chicago_female1.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
  #   end
  # 
  #   context "with geo checkin matches" do
  #     should "create 1 suggestion with chicago_female1 checkin match" do
  #       ThinkingSphinx::Test.run do
  #         @suggestions = SuggestionFactory.create(@chicago_male1, :algorithm => [:geo_checkins, :geo],
  #                                                                 :limit => 10)
  #         assert_equal 1, @suggestions.size
  #         assert_equal [[@chicago_male1, @chicago_female1]], @suggestions.collect(&:users)
  #         assert_equal ['geo_checkin'], @suggestions.collect(&:match)
  #       end
  #     end
  #   end
  # 
  #   context "with geo checkin and geo tag matches" do
  #     setup do
  #       # add another chicago user
  #       @chicago_female2  = User.create!(:name => "Chicago Female 2", :handle => 'chicago_female_2', :gender => 1,
  #                                        :city => @chicago, :lat => 41.850033, :lng => -87.6500523)
  #       # add common user tags
  #       @chicago_male1.tag_ids = @chicago_female2.tag_ids = @chicago_sbux.tag_ids
  #       @chicago_male1.save
  #       @chicago_female2.save
  #       # @chicago_male1.event_location_tagged(@chicago_sbux, true)
  #       # @chicago_female2.event_location_tagged(@chicago_sbux, true)
  #     end
  # 
  #     should "create 1 suggestion with chicago_female1 checkin match and chicago_female2 tag match" do
  #       ThinkingSphinx::Test.run do
  #         @suggestions = SuggestionFactory.create(@chicago_male1, :algorithm => [:geo_checkins, :geo_tags],
  #                                                                 :limit => 10)
  #         assert_equal 2, @suggestions.size
  #         assert_equal [[@chicago_male1, @chicago_female1], [@chicago_male1, @chicago_female2]], @suggestions.collect(&:users)
  #         assert_equal ['geo_checkin', 'geo_tag'], @suggestions.collect(&:match)
  #       end
  #     end
  #   end
  # 
  #   context "with geo checkin and geo matches" do
  #     setup do
  #       # add 2 more chicago users, 1 as a friend
  #       @chicago_female2  = User.create!(:name => "Chicago Female 2", :handle => 'chicago_female_2', :gender => 1,
  #                                        :city => @chicago, :lat => 41.850033, :lng => -87.6500523)
  #       @chicago_female3  = User.create!(:name => "Chicago Female 3", :handle => 'chicago_female_3', :gender => 1,
  #                                        :city => @chicago, :lat => 41.850033, :lng => -87.6500523)
  #       @chicago_male1.friendships.create!(:friend => @chicago_female3)
  #     end
  # 
  #     should "create 2 suggestions with chicago_female1 checkin and chicago_female2 geo match, exclude friend match" do
  #       ThinkingSphinx::Test.run do
  #         @suggestions = SuggestionFactory.create(@chicago_male1, :algorithm => [:geo_checkins, :geo],
  #                                                                 :limit => 10)
  #         assert_equal 2, @suggestions.size
  #         assert_equal [[@chicago_male1, @chicago_female1], [@chicago_male1, @chicago_female2]], @suggestions.collect(&:users)
  #         assert_equal ['geo_checkin', 'geo'], @suggestions.collect(&:match)
  #       end
  #     end
  #   end
  # end

  # context "checkins, geo tag" do
  #   context "with untagged locations" do
  #     setup do
  #       # remove location tags
  #       @chicago_sbux.tag_list = []
  #       @chicago_sbux.save
  #       # create chicago coffee checkins
  #       @chicago_male1.checkins.create!(:location => @chicago_sbux, :checkin_at => 3.days.ago,
  #                                       :source_id => 'sbux', :source_type => 'foursquare')
  #       @chicago_female1.checkins.create!(:location => @chicago_coffee, :checkin_at => 3.days.ago,
  #                                         :source_id => 'coffee', :source_type => 'foursquare')
  #     end
  # 
  #     should "create 0 suggestions" do
  #       ThinkingSphinx::Test.run do
  #         ThinkingSphinx::Test.index
  #         sleep(0.25)
  #         @suggestions = SuggestionFactory.create(@chicago_male1, :algorithm => [:checkins, :geo_tags], :limit => 10)
  #         assert_equal 0, @suggestions.size
  #       end
  #     end
  #   end
  # 
  #   context "with geo tag matches" do
  #     setup do
  #       # create chicago coffee checkins
  #       @chicago_male1.checkins.create!(:location => @chicago_sbux, :checkin_at => 3.days.ago,
  #                                       :source_id => 'sbux', :source_type => 'foursquare')
  #       @chicago_female1.checkins.create!(:location => @chicago_coffee, :checkin_at => 3.days.ago,
  #                                         :source_id => 'coffee', :source_type => 'foursquare')
  #     end
  # 
  #     should 'create 1 suggestion with chicago female coffee tag' do
  #       ThinkingSphinx::Test.run do
  #         ThinkingSphinx::Test.index
  #         sleep(0.25)
  #         @suggestions = SuggestionFactory.create(@chicago_male1, :algorithm => [:checkins, :geo_tags], :limit => 10)
  #         assert_equal 1, @suggestions.size
  #         assert_equal [[@chicago_male1, @chicago_female1]], @suggestions.collect(&:users)
  #         assert_equal ['radius_tag'], @suggestions.collect(&:match)
  #       end
  #     end
  #   end
  # 
  #   context "with no geo tag matches, but tag matches outside radius" do
  #     setup do
  #       # create chicago + boston coffee checkins
  #       @chicago_male1.checkins.create!(:location => @chicago_sbux, :checkin_at => 3.days.ago,
  #                                       :source_id => 'sbux', :source_type => 'foursquare')
  #       @boston_female1.checkins.create!(:location => @boston_coffee, :checkin_at => 3.days.ago,
  #                                        :source_id => 'coffee', :source_type => 'foursquare')
  #     end
  # 
  #     should "create 0 suggestions" do
  #       ThinkingSphinx::Test.run do
  #         ThinkingSphinx::Test.index
  #         sleep(0.25)
  #         @suggestions = SuggestionFactory.create(@chicago_male1, :algorithm => [:checkins, :geo_tags], :limit => 10)
  #         assert_equal 0, @suggestions.size
  #       end
  #     end
  #   end
  # end
  # 
  # context "checkins, tag" do
  #   setup do
  #     # create chicago + boston coffee checkins
  #     @chicago_male1.checkins.create!(:location => @chicago_sbux, :checkin_at => 3.days.ago,
  #                                     :source_id => 'sbux', :source_type => 'foursquare')
  #     @boston_female1.checkins.create!(:location => @boston_coffee, :checkin_at => 3.days.ago,
  #                                      :source_id => 'coffee', :source_type => 'foursquare')
  #   end
  # 
  #   should "create 1 suggestion" do
  #     ThinkingSphinx::Test.run do
  #       ThinkingSphinx::Test.index
  #       sleep(0.25)
  #       @suggestions = SuggestionFactory.create(@chicago_male1, :algorithm => [:checkins, :tags], :limit => 10)
  #       assert_equal 1, @suggestions.size
  #       assert_equal [[@chicago_male1, @boston_female1]], @suggestions.collect(&:users)
  #       assert_equal ['tag'], @suggestions.collect(&:match)
  #     end
  #   end
  # end
  # 
  # context "checkins, geo, gender algorithm" do
  #   context "with geo and gender matches" do
  #   
  #   end
  # 
  #   context "with only gender matches" do
  #     setup do
  #       # create at least 1 boston checkin
  #       @boston_male1.checkins.create!(:location => @boston_sbux, :checkin_at => 3.days.ago,
  #                                      :source_id => 'sbux', :source_type => 'foursquare')
  #       # remove boston female
  #       @boston_female1.destroy
  #     end
  # 
  #     should "create 2 suggestions with female users" do
  #       ThinkingSphinx::Test.run do
  #         ThinkingSphinx::Test.index
  #         sleep(0.25)
  #         @suggestions = SuggestionFactory.create(@boston_male1, :algorithm => [:checkins, :geo, :gender], :limit => 10)
  #         assert_equal 2, @suggestions.size
  #         assert_equal [[@boston_male1, @chicago_female1], [@boston_male1, @newyork_female1]], @suggestions.collect(&:users)
  #         assert_equal ['gender', 'gender'], @suggestions.collect(&:match)
  #       end
  #     end
  #   end
  # end

end