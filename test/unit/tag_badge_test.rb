require 'test_helper'

class TagBadgeTest < ActiveSupport::TestCase

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

  should "not create user tag badgings without matching tag badges" do
    # create chicago checkins
    @chicago_male1.checkins.create(:location => @chicago_sbux, :checkin_at => 3.days.ago, :source_id => 'sbux', :source_type => 'foursquare')
    # should not add tag badges
    @chicago_male1.async_add_tag_badges
    assert_equal [], @chicago_male1.tag_badges.collect(&:name)
    # create tag badge
    @tb1 = TagBadge.create(:regex => "cheese|pizza", :name => 'Caffeine Junkie')
    # should not add tag badges
    @chicago_male1.async_add_tag_badges
    assert_equal [], @chicago_male1.tag_badges.collect(&:name)
    assert_equal [], @chicago_male1.tag_badges_list
  end

  should "create user tag badgings using location tags" do
    # create chicago checkins
    @chicago_male1.checkins.create(:location => @chicago_sbux, :checkin_at => 3.days.ago, :source_id => 'sbux', :source_type => 'foursquare')
    # create tag badge
    @tb1 = TagBadge.create(:regex => "coffee|coffee shop", :name => 'Caffeine Junkie')
    @chicago_male1.async_add_tag_badges
    assert_equal ['Caffeine Junkie'], @chicago_male1.tag_badges.collect(&:name)
    assert_equal ['Caffeine Junkie'], @chicago_male1.tag_badges_list
  end

end