require 'test_helper'

class InvitationsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  context "routes" do
    should route(:get, "/invite").to(:controller => 'invitations', :action => 'new')
    should route(:get, "/invitees/search").to(:controller => 'invitations', :action => 'search')
  end

  context "search" do
    should "search outlately users" do
      @user = Factory.create(:user, :handle => 'outlater', :member => 1)
      @user.email_addresses.create!(:address => "outlater@outlately.com")
      set_beta
      sign_in :user, @user
      get :search, :q => "out", :format => 'json'
      assert_equal "application/json", @response.content_type
      @json = JSON.parse(@response.body)
      assert_equal 'ok', @json['status']
      assert_equal [{'handle' => 'outlater', 'email' => 'outlater@outlately.com', 'source' => 'Outlately'}],
                   @json['invitees']
    end

    should "search invited users" do
      @user = Factory.create(:user, :handle => 'outlater', :member => 1)
      @user.invitations.create(:recipient_email => 'invitee@outlately.com')
      set_beta
      sign_in :user, @user
      get :search, :q => "invite", :format => 'json'
      assert_equal "application/json", @response.content_type
      @json = JSON.parse(@response.body)
      assert_equal 'ok', @json['status']
      assert_equal [{'handle' => 'invitee@outlately.com', 'email' => 'invitee@outlately.com', 'source' => 'Invite'}],
                   @json['invitees']
    end
    
    should "include valid email addresses" do
      @user = Factory.create(:user, :handle => 'outlater', :member => 1)
      @user.email_addresses.create!(:address => "outlater@outlately.com")
      set_beta
      sign_in :user, @user
      get :search, :q => "user@outlately.com", :format => 'json'
      assert_equal "application/json", @response.content_type
      @json = JSON.parse(@response.body)
      assert_equal 'ok', @json['status']
      assert_equal [{'handle' => 'user@outlately.com', 'email' => 'user@outlately.com', 'source' => 'Email'}],
                   @json['invitees']
    end
  end

end