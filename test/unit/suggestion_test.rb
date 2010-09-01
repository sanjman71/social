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
    should "start in suggested state" do
      @options = Hash[:actor1_attributes => {:user => @user1}, :actor2_attributes => {:user => @user2},
                      :location => @loc1, :when => 'next weeks']
      @suggestion = Suggestion.create(@options)
      assert @suggestion.valid?
      assert_equal 'suggested', @suggestion.state
      assert_equal 'signaled', @suggestion.actor1.state
      assert_equal 'signaled', @suggestion.actor2.state
    end
    
    should "reject" do
      @options = Hash[:actor1_attributes => {:user => @user1}, :actor2_attributes => {:user => @user2},
                      :location => @loc1, :when => 'next weeks']
      @suggestion = Suggestion.create(@options)
      @actor1     = @suggestion.actor1
      @actor2     = @suggestion.actor2
      # actor1 rejects, should change suggeestion to 'rejected'
      @actor1.reject!
      assert_equal 'rejected', @actor1.state
      assert_equal 'rejected', @suggestion.reload.state
      # xxx - not sure about actor2
    end

    should "reschedule, confirm" do
      @options = Hash[:actor1_attributes => {:user => @user1}, :actor2_attributes => {:user => @user2},
                      :location => @loc1, :when => 'next weeks']
      @suggestion = Suggestion.create(@options)
      @actor1     = @suggestion.actor1
      @actor2     = @suggestion.actor2
      # actor1 reschedules, should change suggestion to 'rescheduling', actor2 to 'signaled'
      @actor1.reschedule!
      assert_equal 'rescheduled', @actor1.state
      assert_equal 'rescheduling', @suggestion.reload.state
      assert_equal 'signaled', @actor2.state
      # actor1 confirms, should change suggestion to 'confirming', actor2 remains 'signaled'
      @actor1.confirm!
      assert_equal 'confirmed', @actor1.state
      assert_equal 'confirming', @suggestion.reload.state
      assert_equal 'signaled', @actor2.state
      # actor2 confirms, should change suggestion to 'confirmed'
      @actor2.confirm!
      assert_equal 'confirmed', @actor2.state
      assert_equal 'confirmed', @suggestion.reload.state
    end
  end
end