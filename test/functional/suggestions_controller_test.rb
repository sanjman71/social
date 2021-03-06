require 'test_helper'

class SuggestionsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  context "routes" do
    should route(:get, "/suggestions").to(:controller => 'suggestions', :action => 'index')
    should route(:get, "/suggestions/filter:1,3").
      to(:controller => 'suggestions', :action => 'index', :ids => '1,3')
    should route(:put, "/suggestions/1/decline").
      to(:controller => 'suggestions', :action => 'decline', :id => '1')
    should route(:put, "/suggestions/1/confirm").
      to(:controller => 'suggestions', :action => 'confirm', :id => '1')
    should route(:post, "/suggestions/1/schedule").
      to(:controller => 'suggestions', :action => 'schedule', :id => '1')
    should route(:post, "/suggestions/1/reschedule").
      to(:controller => 'suggestions', :action => 'reschedule', :id => '1')
    should route(:post, "/suggestions/1/relocate").
      to(:controller => 'suggestions', :action => 'relocate', :id => '1')
    should route(:post, "/suggestions/1/relocate/5").
      to(:controller => 'suggestions', :action => 'relocate', :id => '1', :location_id => '5')
  end

  def setup
    @user1 = Factory.create(:user, :handle => 'User1', :member => 1)
    @user2 = Factory.create(:user, :handle => "User2", :member => 1)
    @loc1  = Location.create!(:name => "The Coffee House", :country => countries(:us))
    @loc2  = Location.create!(:name => "Starbucks", :country => countries(:us))
    # create suggestion
    @options    = Hash[:party1_attributes => {:user => @user1}, :party2_attributes => {:user => @user2},
                       :location => @loc1, :when => 'next week']
    @suggestion = Suggestion.create!(@options)
  end

  context "index" do
    should "show all suggestions" do
      sign_in @user1
      set_beta
      get :index
      assert_equal nil, assigns(:filter)
      assert_equal [@suggestion], assigns(:suggestions)
    end
    
    should "show filtered suggestions" do
      sign_in @user1
      set_beta
      get :index, :ids => "#{@suggestion.id}"
      assert_equal [@suggestion.id], assigns(:filter)
      assert_equal [@suggestion], assigns(:suggestions)
    end
  end

  context "show" do
    should "tell both parties a suggestion was created" do
      assert_equal "initialized", @suggestion.state
      sign_in @user1
      set_beta
      get :show, :id => @suggestion.id
      assert_equal @suggestion.party2, assigns(:other_party)
      assert_select "div#text", :text => "outlate.ly suggests meeting User2 at The Coffee House next week." +
                                         "\n\nPick a date as your next step."
      assert_select "a#suggestion_pick_date", 1
      assert_select "a#suggestion_decline", 1
      assert_response :success
    end
    
    context "declined suggestion" do
      setup do
        # party1 declines
        @suggestion.party_declines(@suggestion.party1)
        assert_equal "bailed", @suggestion.state
      end
      
      should "tell party1 they declined suggestion" do
        sign_in @user1
        set_beta
        get :show, :id => @suggestion.id
        assert_select "div#text", :text => "outlate.ly suggests meeting User2 at The Coffee House next week." +
                                           "\n\nYou declined this suggestion."
        assert_select "a#suggestion_pick_date", 0
        assert_select "a#suggestion_decline", 0
      end

      should "tell party2 they got dumped" do
        sign_in @user2
        set_beta
        get :show, :id => @suggestion.id
        assert_select "div#text", :text => "outlate.ly suggests meeting User1 at The Coffee House next week." +
                                           "\n\nThey declined this suggestion."
        assert_select "a#suggestion_pick_date", 0
        assert_select "a#suggestion_decline", 0
      end
    end
    
    context "scheduled suggestion" do
      setup do
        # party1 schedules a date and time
        @suggestion.party_schedules(@suggestion.party1, :scheduled_at => "10/01/2010")
        @suggestion.party_confirms(@suggestion.party1, :event => 'schedule')
        assert_equal "talking", @suggestion.state
        assert_equal "confirmed", @suggestion.party1.state
        assert_equal "schedule", @suggestion.party1.event
        assert_equal "scheduled", @suggestion.party2.state
        assert_equal "", @suggestion.party2.event
      end
      
      should "tell party1 they scheduled a date and time" do
        sign_in @user1
        set_beta
        get :show, :id => @suggestion.id
        assert_select "div#text",
          :text => "You suggested meeting User2 at The Coffee House on Friday, October 01, 2010 at 12:00 AM." +
                   "\n\nWe are waiting for User2 to confirm.  You can re-schedule at any time."              
        assert_select "a#suggestion_pick_date", 0
        assert_select "a#suggestion_repick_date", 1
        assert_select "a#suggestion_confirm", 0
        assert_select "a#suggestion_decline", 1
      end

      should "tell party2 that party1 scheduled a date and time" do
        sign_in @user2
        set_beta
        get :show, :id => @suggestion.id
        assert_select "div#text",
          :text => "User1 suggested meeting at The Coffee House on Friday, October 01, 2010 at 12:00 AM." +
                   "\nIts your turn to confirm."
        assert_select "a#suggestion_pick_date", 0
        assert_select "a#suggestion_repick_date", 1
        assert_select "a#suggestion_confirm", 1
        assert_select "a#suggestion_decline", 1
      end
    end
    
    context "rescheduled suggestion" do
      setup do
        # party1 schedules a date and time, confirms
        @suggestion.party_schedules(@suggestion.party1, :scheduled_at => "10/01/2010")
        @suggestion.party_confirms(@suggestion.party1, :event => 'schedule')
        # party2 reschedules, confirms
        @suggestion.party_reschedules(@suggestion.party2, :rescheduled_at => "10/05/2010")
        @suggestion.party_confirms(@suggestion.party2, :event => 'reschedule')
        assert_equal "talking", @suggestion.state
        assert_equal "scheduled", @suggestion.party1.state
        assert_equal "", @suggestion.party1.event
        assert_equal "confirmed", @suggestion.party2.state
        assert_equal "reschedule", @suggestion.party2.event
      end
      
      should "tell party1 that party2 rescheduled" do
        sign_in @user1
        set_beta
        get :show, :id => @suggestion.id
        assert_select "div#text",
          :text => "User2 rescheduled at The Coffee House for Tuesday, October 05, 2010 at 12:00 AM." +
                   "\n\nNow you just need to confirm."
        assert_select "a#suggestion_pick_date", 0
        assert_select "a#suggestion_repick_date", 1
        assert_select "a#suggestion_confirm", 1
        assert_select "a#suggestion_decline", 1
      end

      should "tell party2 they rescheduled" do
        sign_in @user2
        set_beta
        get :show, :id => @suggestion.id
        assert_select "div#text",
          :text => "You rescheduled at The Coffee House for Tuesday, October 05, 2010 at 12:00 AM." +
                   "\n\nWe are waiting for User1 to confirm."
        assert_select "a#suggestion_pick_date", 0
        assert_select "a#suggestion_repick_date", 1
        assert_select "a#suggestion_confirm", 0
        assert_select "a#suggestion_decline", 1
      end
    end
  end

  context "decline" do
    should "mark suggestion as bailed" do
      sign_in @user1
      set_beta
      put :decline, :id => @suggestion.id
      assert_equal 'bailed', @suggestion.reload.state
      assert_false @suggestion.party1.reload.alert?
      assert_true @suggestion.party2.reload.alert?
      assert_redirected_to "/suggestions"
    end
  end

  context "relocate" do
    should "change location to starbucks" do
      sign_in @user1
      set_beta
      post :relocate, :id => @suggestion.id, :location_id => @loc2.id
      assert_response :redirect
      assert_equal "Your suggestion was re-located!", flash[:notice]
      # should change location
      assert_equal @loc2, @suggestion.reload.location
    end
  end

  context "schedule" do
    should "not allow in scheduled state" do
      @suggestion.party_schedules(@suggestion.party1)
      # party1 schedules
      sign_in @user1
      set_beta
      post :schedule, :id => @suggestion.id, :suggestion => {:date => '10/1/2010'}
      assert_equal 'talking', @suggestion.reload.state
      assert_equal "Whoops, that's not allowed", flash[:error]
    end

    context 'js' do
      should "set scheduled_at date, change party states, set alert for other party" do
        # party1 schedules
        sign_in @user1
        set_beta
        post :schedule, :format => 'js', :id => @suggestion.id, :suggestion => {:date => '10/01/2010'}
        assert_equal 'confirmed', @suggestion.reload.party1.state
        assert_equal 'scheduled', @suggestion.reload.party2.state
        # should set scheduled datetime
        assert_equal '20101001T000000', @suggestion.reload.scheduled_at.to_s(:datetime_schedule)
        assert_equal 'talking', @suggestion.reload.state
        # should set party1 event, clear party2 event
        assert_equal 'schedule', @suggestion.reload.party1.event
        assert_equal '', @suggestion.reload.party2.event
        assert_false @suggestion.reload.party1.alert?
        assert_true @suggestion.reload.party2.alert?
        # assert_content_type "text/javascript"
        assert_response :success
      end
    end
    
    context 'html' do
      should "redirect" do
        # party1 schedules
        sign_in @user1
        set_beta
        post :schedule, :id => @suggestion.id, :suggestion => {:date => '10/01/2010'}
        assert_redirected_to "/suggestions"
      end
    end
  end
  
  context "reschedule" do
    setup do
      # party1 schedules
      @suggestion.party_schedules(@suggestion.party1)
    end
    
    context 'js' do
      should "set scheduled_at date, change party states" do
        # party2 schedules
        sign_in @user2
        set_beta
        post :reschedule, :format => 'js', :id => @suggestion.id, :suggestion => {:date => '12/01/2010'}
        # should change party states to scheduled
        assert_equal 'scheduled', @suggestion.reload.party1.state
        assert_equal 'confirmed', @suggestion.reload.party2.state
        # should set rescheduled datetime
        assert_equal '20101201T000000', @suggestion.reload.scheduled_at.to_s(:datetime_schedule)
        # should set party2 event, clear party1 event
        assert_equal '', @suggestion.reload.party1.event
        assert_equal 'reschedule', @suggestion.reload.party2.event
        # assert_content_type "text/javascript"
        assert_response :success
      end
    end
  end
end