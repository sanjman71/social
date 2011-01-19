require 'test_helper'

class BadgeTest < ActiveSupport::TestCase

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

  should "add tag_ids when badge is created" do
    @badge  = Badge.create(:regex => "coffee|tea", :name => 'Caffeine Junkie')
    @coffee = ActsAsTaggableOn::Tag.find_by_name('coffee')
    assert_equal [@coffee.id], @badge.tag_ids.split(",").map(&:to_i)
  end

  should "add tag_ids when badge is updated" do
    @badge  = Badge.create(:regex => "-", :name => 'Caffeine Junkie')
    @coffee = ActsAsTaggableOn::Tag.find_by_name('coffee')
    assert_equal [], @badge.tag_ids.split(",")
    @badge.regex = "coffee|tea"
    @badge.save
    assert_equal [@coffee.id], @badge.reload.tag_ids.split(",").map(&:to_i)
  end

  should "find badge when searching by tag id" do
    @badge  = Badge.create(:regex => "coffee|tea", :name => 'Caffeine Junkie')
    @coffee = ActsAsTaggableOn::Tag.find_by_name('coffee')
    @badges = Badge.search(@coffee.id)
    # @badges = Badge.find(:all, :conditions => ["find_in_set(?,tag_ids)", @coffee.id])
    assert_equal [@badge], @badges
  end

  should "not add badge without matching tags" do
    # create badge
    @badge   = Badge.create(:regex => "cheese|pizza", :name => 'Caffeine Junkie')
    # create chicago locationship
    @chicago_male1.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
    # should not add any badges
    assert_equal 0, @chicago_male1.async_add_badges.size
  end

  should "add badge based on matching checkin location tags" do
    # create chicago checkin locationship
    @chicago_male1.locationships.create!(:location => @chicago_sbux, :my_checkins => 1)
    # create badge
    @badge = Badge.create(:regex => "coffee|coffee shop", :name => 'Caffeine Junkie')
    # should add matching badge
    assert_equal 1, @chicago_male1.async_add_badges.size
    assert_equal ['Caffeine Junkie'], @chicago_male1.badges_list
  end

  should "not add badge based on matching friend location tags" do
    # create chicago friend locationship
    @chicago_male1.locationships.create!(:location => @chicago_sbux, :friend_checkins => 1)
    # create badge
    @badge = Badge.create(:regex => "coffee|coffee shop", :name => 'Caffeine Junkie')
    # should not add badge
    assert_equal 0, @chicago_male1.async_add_badges.size
  end

end