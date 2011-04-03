require 'test_helper'

# deprecated
# class CheckinMatchTest < ActiveSupport::TestCase
# 
#   # turn off transactional fixtures here so we can test sphinx
#   self.use_transactional_fixtures = false
# 
#   def setup
#     @chicago          = cities(:chicago)
#     @newyork          = cities(:new_york)
#     @boston           = cities(:boston)
# 
#     # create locations
#     @chicago_sbux     = Location.create!(:name => "Chicago Starbucks", :country => @us, :city => @chicago,
#                                          :lat => 41.89248300, :lng => -87.6281306000)
#     @chicago_coffee   = Location.create!(:name => "Chicago Coffee", :country => @us, :city => @chicago,
#                                          :lat => 41.8840864000, :lng => -87.6412261000)
#     @chicago_lavazza  = Location.create!(:name => "Chicago Lavazza", :country => @us, :city => @chicago,
#                                          :lat => 41.8840864000, :lng => -87.6412261000)
# 
#     # create users
#     @chicago_male1    = Factory.create(:user, :handle => 'chicago_male_1', :gender => 2, :member => 1,
#                                        :city => @chicago)
#     @chicago_male2    = Factory.create(:user, :handle => 'chicago_male_2', :gender => 2, :member => 1,
#                                        :city => @chicago)
#     @chicago_female1  = Factory.create(:user, :handle => 'chicago_female_1', :gender => 1, :member => 1,
#                                        :city => @chicago)
#     @chicago_female2  = Factory.create(:user, :handle => 'chicago_female_2', :gender => 1, :member => 0,
#                                        :city => @chicago)
#     @chicago_female3  = Factory.create(:user, :handle => 'chicago_female_3', :gender => 1, :member => 0,
#                                        :city => @chicago)
#     # tag coffee locations
#     [@chicago_sbux, @chicago_coffee, @chicago_lavazza].each do |o|
#       o.tag_list = ['cafe', 'coffee']
#       o.save
#     end
#   end
# 
#   def teardown
#     ThinkingSphinx::Test.stop
#     DatabaseCleaner.clean
#   end
# 
#   fast_context "match strategies" do
#     setup do
#       @chi_checkin1 = @chicago_male1.checkins.create!(Factory.attributes_for(:foursquare_checkin,
#                                                                              :location => @chicago_sbux))
#       # checkins at same place, members and non-members
#       @chi_checkin2 = @chicago_female1.checkins.create!(Factory.attributes_for(:foursquare_checkin,
#                                                                                :location => @chicago_sbux))
#       @chi_checkin3 = @chicago_male2.checkins.create!(Factory.attributes_for(:foursquare_checkin,
#                                                                              :location => @chicago_sbux))
#       @chi_checkin4 = @chicago_female2.checkins.create!(Factory.attributes_for(:foursquare_checkin,
#                                                                                :location => @chicago_sbux))
#       # checkins at similar places, members and non-members
#       @chi_checkin5 = @chicago_female1.checkins.create!(Factory.attributes_for(:foursquare_checkin,
#                                                                                :location => @chicago_coffee))
#       @chi_checkin6 = @chicago_male2.checkins.create!(Factory.attributes_for(:foursquare_checkin,
#                                                                              :location => @chicago_coffee))
#       @chi_checkin7 = @chicago_female2.checkins.create!(Factory.attributes_for(:foursquare_checkin,
#                                                                                :location => @chicago_lavazza))
#       @chi_checkin8 = @chicago_female3.checkins.create!(Factory.attributes_for(:foursquare_checkin,
#                                                                                :location => @chicago_lavazza))
#       ThinkingSphinx::Test.start
#     end
# 
#     should "find 2 exact matches, members and non-members" do
#       @matches = @chi_checkin1.match_exact
#       assert_equal 2, ([@chi_checkin2.id, @chi_checkin4.id].to_set & @matches.collect(&:id).to_set).size
#     end
# 
#     should "find 2 similar matches, members and non-members" do
#       @matches = @chi_checkin1.match_similar
#       assert_equal 2, ([@chi_checkin5.id, @chi_checkin7.id].to_set & @matches.collect(&:id).to_set).size
#     end
# 
#     should "find 3 matches strategies, 2 exact and 1 similar, with no repeat checkins or users" do
#       @matches = @chi_checkin1.match_strategies([:exact, :similar, :nearby], :limit => 3)
#       # 2 exact matches
#       assert_equal 2, ([@chi_checkin2.id, @chi_checkin4.id].to_set & @matches.collect(&:id).to_set).size
#       # 1 similar match, no repeat users
#       assert_equal 1, ([@chi_checkin8.id].to_set & @matches.collect(&:id).to_set).size
#     end
#   end
# 
# end