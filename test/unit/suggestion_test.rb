require 'test_helper'

class SuggestionTest < ActiveSupport::TestCase

  def setup
    @user1 = User.create!(:name => "User 1", :handle => 'user1', :member => 1)
    @user2 = User.create!(:name => "User 2", :handle => 'user2', :member => 1)
    @loc1  = Location.create!(:name => "Home", :country => countries(:us))
    @loc2  = Location.create!(:name => "Away", :country => countries(:us))
  end

  context "create" do
    should "start in initialized state" do
      @options = Hash[:party1_attributes => {:user => @user1}, :party2_attributes => {:user => @user2},
                      :location => @loc1, :when => 'next week']
      @suggestion = Suggestion.create(@options)
      assert @suggestion.valid?
      assert_equal 'initialized', @suggestion.state
      assert_equal 'initialized', @suggestion.party1.state
      assert_equal 'initialized', @suggestion.party2.state
      # should set alert flags
      assert_true @suggestion.party1.alert?
      assert_true @suggestion.party2.alert?
      # assert_equal @user1, @suggestion.user1
      # assert_equal @user2, @suggestion.user2
      assert_equal [:bail, :talk], @suggestion.aasm_events_for_current_state.sort
      assert_equal [:decline, :dump, :schedule], @suggestion.party1.aasm_events_for_current_state.sort
      assert_equal [:decline, :dump, :schedule], @suggestion.party2.aasm_events_for_current_state.sort
    end
    
    should "create with scheduled_at format dd/mm/yyyy" do
      @options = Hash[:party1_attributes => {:user => @user1}, :party2_attributes => {:user => @user2},
                      :location => @loc1, :when => 'next week', :scheduled_at => '08/01/2010']
      @suggestion = Suggestion.create(@options)
      assert_equal "20100801T000000", @suggestion.scheduled_at.to_s(:datetime_schedule)
    end

    should "create with scheduled_at format yyyymmdd" do
      @options = Hash[:party1_attributes => {:user => @user1}, :party2_attributes => {:user => @user2},
                      :location => @loc1, :when => 'next week', :scheduled_at => '20100501']
      @suggestion = Suggestion.create(@options)
      assert_equal "20100501T000000", @suggestion.scheduled_at.to_s(:datetime_schedule)
    end
  end

  context "state transitions" do
    should "change location in initialized state without changing states" do
      @options = Hash[:party1_attributes => {:user => @user1}, :party2_attributes => {:user => @user2},
                      :location => @loc1, :when => 'next week']
      @suggestion = Suggestion.create(@options)
      # party1 relocates
      @suggestion.party_relocates(@suggestion.party1, :location => @loc2)
      # should change suggestion location
      assert_equal @loc2, @suggestion.reload.location
    end

    should "decline" do
      @options = Hash[:party1_attributes => {:user => @user1}, :party2_attributes => {:user => @user2},
                      :location => @loc1, :when => 'next week']
      @suggestion = Suggestion.create(@options)
      # party1 declines
      @suggestion.party_declines(@suggestion.party1)
      assert_equal 'declined', @suggestion.party1.state
      assert_equal 'dumped', @suggestion.party2.state
      assert_equal 'bailed', @suggestion.reload.state
      assert_equal [], @suggestion.party1.aasm_events_for_current_state.sort
      assert_equal [], @suggestion.party2.aasm_events_for_current_state.sort
    end

    should "schedule, then confirm" do
      @options = Hash[:party1_attributes => {:user => @user1}, :party2_attributes => {:user => @user2},
                      :location => @loc1, :when => 'next week']
      @suggestion = Suggestion.create(@options)
      # party1 schedules - should change party1 to confirmed, party2 to scheduled, send email to party2
      @tomorrow   = Time.zone.now.end_of_day + 1.second + 10.hours
      @suggestion.party_schedules(@suggestion.party1, :scheduled_at => @tomorrow)
      assert_equal 'scheduled', @suggestion.party1.state
      assert_equal 'scheduled', @suggestion.party2.state
      assert_equal 'talking', @suggestion.reload.state
      assert_equal 1, match_delayed_jobs(/async_scheduled_event/)
      # compare times without subsec
      assert_equal @tomorrow.to_s(:datetime_schedule), @suggestion.scheduled_at.to_s(:datetime_schedule)
      assert_equal [:confirm, :decline, :dump, :relocate, :reschedule], @suggestion.party1.aasm_events_for_current_state.sort
      assert_equal [:confirm, :decline, :dump, :relocate, :reschedule], @suggestion.party2.aasm_events_for_current_state.sort
      # party1 confirms - should change party2 state to 'scheduled', and send email
      @suggestion.party_confirms(@suggestion.party1)
      assert_equal 'confirmed', @suggestion.party1.state
      assert_equal 'scheduled', @suggestion.party2.state
      assert_equal 'talking', @suggestion.reload.state
      assert_equal [:decline, :dump, :relocate, :reschedule], @suggestion.party1.aasm_events_for_current_state.sort
      assert_equal [:confirm, :decline, :dump, :relocate, :reschedule], @suggestion.party2.aasm_events_for_current_state.sort
      assert_equal 1, match_delayed_jobs(/async_confirmed_event/)
      Delayed::Job.delete_all
      # party2 confirms, should send another email
      @suggestion.party_confirms(@suggestion.party2)
      assert_equal 'confirmed', @suggestion.party2.state
      assert_equal 'confirmed', @suggestion.party1.state
      assert_equal 'going_out', @suggestion.reload.state
      assert_equal [:decline, :dump, :relocate, :reschedule], @suggestion.party1.aasm_events_for_current_state.sort
      assert_equal [:decline, :dump, :relocate, :reschedule], @suggestion.party2.aasm_events_for_current_state.sort
      assert_equal 1, match_delayed_jobs(/async_confirmed_event/)
    end
    
    should "schedule, then re-schedule" do
      @options = Hash[:party1_attributes => {:user => @user1}, :party2_attributes => {:user => @user2},
                      :location => @loc1, :when => 'next week']
      @suggestion = Suggestion.create(@options)
      # party1 schedules
      @suggestion.party_schedules(@suggestion.party1)
      # party2 reschedules
      @suggestion.party_reschedules(@suggestion.party2)
      assert_equal 'scheduled', @suggestion.party1.state
      assert_equal 'scheduled', @suggestion.party2.state
      assert_equal 'talking', @suggestion.reload.state
      assert_equal [:confirm, :decline, :dump, :relocate, :reschedule], @suggestion.party1.aasm_events_for_current_state.sort
      assert_equal [:confirm, :decline, :dump, :relocate, :reschedule], @suggestion.party2.aasm_events_for_current_state.sort
      assert_equal 1, match_delayed_jobs(/async_rescheduled_event/)
    end

    should "relocate in scheduled state" do
      @options = Hash[:party1_attributes => {:user => @user1}, :party2_attributes => {:user => @user2},
                      :location => @loc1, :when => 'next week']
      @suggestion = Suggestion.create(@options)
      # party1 schedules
      @suggestion.party_schedules(@suggestion.party1)
      # party2 relocates
      @suggestion.party_relocates(@suggestion.party2, :location => @loc2)
      # should change suggestion location and send email
      assert_equal @loc2, @suggestion.reload.location
      assert_equal 'scheduled', @suggestion.party1.state
      assert_equal 'scheduled', @suggestion.party2.state
      assert_equal 'talking', @suggestion.reload.state
      assert_equal [:confirm, :decline, :dump, :relocate, :reschedule], @suggestion.party1.aasm_events_for_current_state.sort
      assert_equal [:confirm, :decline, :dump, :relocate, :reschedule], @suggestion.party2.aasm_events_for_current_state.sort
      assert_equal 1, match_delayed_jobs(/async_relocated_event/)
    end

    should "relocate in confirmed state" do
      
    end
  end
end