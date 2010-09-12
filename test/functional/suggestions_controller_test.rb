require 'test_helper'

class SuggestionsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  context "routes" do
    should route(:put, "/suggestions/1/decline").to(:controller => 'suggestions', :action => 'decline', :id => '1')
    should route(:put, "/suggestions/1/confirm").to(:controller => 'suggestions', :action => 'confirm', :id => '1')
    should route(:post, "/suggestions/1/schedule").to(:controller => 'suggestions', :action => 'schedule', :id => '1')
    should route(:post, "/suggestions/1/reschedule").to(:controller => 'suggestions', :action => 'reschedule', :id => '1')
  end

  def setup
    @user1 = Factory.create(:user)
    @user2 = Factory.create(:user)
    @us    = Factory(:us)
    @loc1  = Location.create(:name => "Home", :country => @us)
    # create suggestion
    @options    = Hash[:party1_attributes => {:user => @user1}, :party2_attributes => {:user => @user2},
                       :location => @loc1, :when => 'next week']
    @suggestion = Suggestion.create(@options)
  end

  context "decline" do
    should "mark suggestion as bailed" do
      sign_in @user1
      set_beta
      put :decline, :id => @suggestion.id
      assert_equal 'bailed', @suggestion.reload.state
      assert_false @suggestion.party1.reload.alert?
      assert_true @suggestion.party2.reload.alert?
      assert_redirected_to "/suggestions/#{@suggestion.id}"
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
      should "set scheduled_at date, send message to other party, set alert for other party" do
        # party1 schedules
        sign_in @user1
        set_beta
        post :schedule, :format => 'js', :id => @suggestion.id, :suggestion => {:date => '10/01/2010'}
        assert_equal 'talking', @suggestion.reload.state
        assert_equal 'confirmed', @suggestion.party1.reload.state
        assert_equal 'scheduled', @suggestion.party2.reload.state
        assert_false @suggestion.party1.reload.alert?
        assert_true @suggestion.party2.reload.alert?
        assert_equal '20101001T000000', @suggestion.reload.scheduled_at.to_s(:datetime_schedule)
        assert_equal 'You suggested a date and time', @suggestion.party1.message
        assert_equal "#{@user1.handle} suggested a date and time", @suggestion.party2.message
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
        assert_redirected_to "/suggestions/#{@suggestion.id}"
      end
    end
  end
end