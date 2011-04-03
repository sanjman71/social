require 'test_helper'

class BadgeTest < ActiveSupport::TestCase

  def setup
    # create locations
    @chicago_sbux   = Location.create!(:name => "Chicago Starbucks", :country => countries(:us),
                                       :city => cities(:chicago))
    @chicago_coffee = Location.create!(:name => "Chicago Coffee", :country => countries(:us),
                                       :city => cities(:chicago))
    @chicago_lous   = Location.create!(:name => "Chicago Lou Malnati's", :country => countries(:us),
                                       :city => cities(:chicago))
    @chicago_pizza  = Location.create!(:name => "Chicago Pizza", :country => countries(:us),
                                       :city => cities(:chicago))
    # tag coffee places
    [@chicago_sbux, @chicago_coffee].each do |o|
      o.tag_list = ['cafe', 'coffee']
      o.save
    end
    # create users
    @chicago_male1  = User.create!(:name => "Chicago Male 1", :handle => 'chicago_male_1', :gender => 2,
                                   :city => cities(:chicago), :member => 1)
  end

  should "add tag_ids when badge is created" do
    @badge  = Badge.create!(:regex => "coffee|tea", :name => 'Caffeine Junkie', :tagline => 'Mainlines espresso')
    @coffee = ActsAsTaggableOn::Tag.find_by_name('coffee')
    assert_equal [@coffee.id], @badge.tag_ids.split(",").map(&:to_i)
  end

  should "add tag_ids when badge regex is updated" do
    @badge  = Badge.create!(:name => 'Caffeine Junkie', :tagline => 'Mainlines espresso')
    @coffee = ActsAsTaggableOn::Tag.find_by_name('coffee')
    assert_nil @badge.tag_ids
    @badge.regex = "coffee|tea"
    @badge.save
    assert_equal [@coffee.id], @badge.reload.tag_ids.split(",").map(&:to_i)
  end

  should "add tag_ids and update regex when tags are added using add_tags method" do
    @badge  = Badge.create!(:name => 'Caffeine Junkie', :tagline => 'Mainlines espresso')
    @coffee = ActsAsTaggableOn::Tag.find_by_name('coffee')
    assert_nil @badge.tag_ids
    @badge.add_tags('coffee,tea')
    @badge.save
    assert_equal "coffee|tea", @badge.reload.regex
    assert_equal [@coffee.id], @badge.reload.tag_ids.split(",").map(&:to_i)
  end

  should "remove tag_ids and update regex when tags are removed using remove_tags method" do
    @badge  = Badge.create!(:name => 'Caffeine Junkie', :tagline => 'Mainlines espresso',
                            :regex => "coffee|coffee shop")
    @badge.remove_tags('coffee,tea')
    @badge.save
    assert_equal "coffee shop", @badge.reload.regex
    assert_equal [], @badge.reload.tag_ids.split(",").map(&:to_i)
  end

  should "find badge when searching by tag id" do
    @badge  = Badge.create!(:regex => "coffee|tea", :name => 'Caffeine Junkie', :tagline => 'Mainlines espresso')
    @coffee = ActsAsTaggableOn::Tag.find_by_name('coffee')
    @badges = Badge.search(@coffee.id)
    assert_equal [@badge], @badges
  end

  should "not add badge without matching tags" do
    Resque.reset!
    # add location tags
    @chicago_pizza.tag_list.add('pizza')
    @chicago_pizza.save
    # create badge (with existing tags)
    @badge = Badge.create!(:regex => "pizza", :name => 'Pizza Junkie', :tagline => 'Sucka cheese')
    # create chicago checkin, update locationship
    @chicago_male1.checkins.create!(Factory.attributes_for(:foursquare_checkin, :location => @chicago_sbux))
    # run resque jobs
    Resque.run!
    # should not add any badges
    assert_equal [], @chicago_male1.reload.badges_list
    # add location tags using a pre-existing tag to a new location
    @chicago_sbux.tag_list.add('pizza')
    @chicago_sbux.save
    # trigger location_tagged event
    @chicago_sbux.event_location_tagged
    # run resque jobs
    Resque.full_run!
    # should add matching badge
    assert_equal ['Pizza Junkie'], @chicago_male1.reload.badges_list
  end

  should "add badge based on matching checkin location tags" do
    Resque.reset!
    # create chicago checkin
    @chicago_male1.checkins.create!(Factory.attributes_for(:foursquare_checkin, :location => @chicago_sbux))
    # create badge
    @badge = Badge.create!(:regex => "coffee|coffee shop", :name => 'Caffeine Junkie',
                           :tagline => 'Mainlines espresso')
    # run resque jobs
    Resque.run!
    # should add matching badge
    assert_equal ['Caffeine Junkie'], @chicago_male1.reload.badges_list
  end

end