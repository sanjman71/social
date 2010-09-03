require 'test_helper'

class SuggestionTest < ActiveSupport::TestCase

  def setup
    @user1 = User.create(:name => "User 1", :handle => 'user1')
    assert @user1.valid?
    @user2 = User.create(:name => "User 2", :handle => 'user2')
    assert @user2.valid?
    @us    = Factory(:us)
    @loc1  = Location.create(:name => "Home", :country => @us)
  end

  context "create" do
    should "start in initialized state with default messages" do
      @options = Hash[:actor1_attributes => {:user => @user1}, :actor2_attributes => {:user => @user2},
                      :location => @loc1, :when => 'next weeks']
      @suggestion = Suggestion.create(@options)
      assert @suggestion.valid?
      assert_equal 'initialized', @suggestion.state
      assert_equal 'initialized', @suggestion.actor1.state
      assert_equal 'initialized', @suggestion.actor2.state
      assert_equal 'A suggested date', @suggestion.actor1.message
      assert_equal 'A suggested date', @suggestion.actor2.message
    end
    
    should "decline" do
      @options = Hash[:actor1_attributes => {:user => @user1}, :actor2_attributes => {:user => @user2},
                      :location => @loc1, :when => 'next week']
      @suggestion = Suggestion.create(@options)
      # actor1 declines
      @suggestion.user_declines(@suggestion.actor1)
      assert_equal 'declined', @suggestion.actor1.state
      assert_equal 'dumped', @suggestion.actor2.state
      assert_equal 'bailed', @suggestion.reload.state
      assert_equal "user1 declined", @suggestion.actor2.message
    end

    should "schedule, then confirm" do
      @options = Hash[:actor1_attributes => {:user => @user1}, :actor2_attributes => {:user => @user2},
                      :location => @loc1, :when => 'next week']
      @suggestion = Suggestion.create(@options)
      # actor1 schedules
      @suggestion.user_schedules(@suggestion.actor1)
      assert_equal 'scheduled', @suggestion.actor1.state
      assert_equal 'scheduled', @suggestion.actor2.state
      assert_equal 'talking', @suggestion.reload.state
      assert_equal "user1 suggested a date and time", @suggestion.actor2.message
      # actor1 confirms - should change actor2 state to 'scheduled'
      @suggestion.user_confirms(@suggestion.actor1)
      assert_equal 'confirmed', @suggestion.actor1.state
      assert_equal 'scheduled', @suggestion.actor2.state
      assert_equal 'talking', @suggestion.reload.state
      assert_equal "user1 confirmed", @suggestion.actor2.message
      # actor2 confirms
      @suggestion.user_confirms(@suggestion.actor2)
      assert_equal 'confirmed', @suggestion.actor2.state
      assert_equal 'confirmed', @suggestion.actor1.state
      assert_equal 'going_out', @suggestion.reload.state
    end
    
    should "schedule, then re-schedule" do
      @options = Hash[:actor1_attributes => {:user => @user1}, :actor2_attributes => {:user => @user2},
                      :location => @loc1, :when => 'next week']
      @suggestion = Suggestion.create(@options)
      # actor1 schedules
      @suggestion.user_schedules(@suggestion.actor1)
      # actor2 reschedules
      @suggestion.user_reschedules(@suggestion.actor2)
      assert_equal 'scheduled', @suggestion.actor1.state
      assert_equal 'scheduled', @suggestion.actor2.state
      assert_equal 'talking', @suggestion.reload.state
      assert_equal "user2 suggested another date and time", @suggestion.actor1.message
    end
    
  end
end