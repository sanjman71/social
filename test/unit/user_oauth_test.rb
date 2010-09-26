require 'test_helper'

class UserOauthTest < ActiveSupport::TestCase

  context "facebook oauth create" do
    setup do
      @user1 = User.create(:name => "User 1", :handle => 'user1')
      assert @user1.valid?
    end

    should "create oauth, set user facebook id, facebook photo" do
      json_data    = File.open("#{Rails.root}/test/data/facebook_user.json")
      access_token = OAuth2::AccessToken.new('1', '2')
      # stub access token
      access_token.stubs(:get).returns(json_data)
      User.find_for_facebook_oauth(access_token, @user1)
      # should set user facebook id
      assert @user1.facebook_id
      # should create user facebook oauth
      assert_equal 1, @user1.oauths.facebook.count
      # should create user facebook photo
      assert_equal 1, @user1.photos.facebook.count
      assert_equal [1], @user1.photos.facebook.collect(&:priority)
      assert_equal ["https://graph.facebook.com/633015812/picture?type=square"], @user1.photos.facebook.collect(&:url)
    end
  end

  context "foursquare oauth create" do
    setup do
      @user1 = User.create(:name => "User 1", :handle => 'user1')
      assert @user1.valid?
    end

    should "create oauth, set user foursquare id, foursquare photo" do
      json_data    = File.open("#{Rails.root}/test/data/foursquare_user.json")
      access_token = OAuth2::AccessToken.new('1', '2')
      # create mock to hold json data
      json_mock    = mock()
      json_mock.stubs(:body).returns(json_data)
      # stub access token
      access_token.stubs(:get).returns(json_mock)
      User.find_for_foursquare_oauth(access_token, @user1)
      # should create user foursquare oauth
      assert_equal 1, @user1.oauths.foursquare.count
      # should set user foursquare id
      assert @user1.foursquare_id
      # should create user foursquare photo
      assert_equal 1, @user1.photos.foursquare.count
      assert_equal [3], @user1.photos.foursquare.collect(&:priority)
      assert_equal ["http://foursquare.com/img/blank_boy.png"], @user1.photos.foursquare.collect(&:url)
    end
  end

  context "twitter oauth create" do
    setup do
      @user1 = User.create(:name => "User 1", :handle => 'user1')
      assert @user1.valid?
    end

    should "create oauth, set user twitter id, twitter photo" do
      json_data    = File.open("#{Rails.root}/test/data/twitter_user.json")
      access_token = OAuth2::AccessToken.new('1', '2')
      # create mock to hold json data
      json_mock    = mock()
      json_mock.stubs(:body).returns(json_data)
      # stub access token
      access_token.stubs(:get).returns(json_mock)
      User.find_for_twitter_oauth(access_token, @user1)
      # should create user twitter oauth
      assert_equal 1, @user1.oauths.twitter.count
      # should set user twitter id
      assert @user1.twitter_id
      # should create user twitter photo
      assert_equal 1, @user1.photos.twitter.count
      assert_equal [5], @user1.photos.twitter.collect(&:priority)
      assert_equal ["http://s.twimg.com/a/1284949838/images/default_profile_0_normal.png"], @user1.photos.twitter.collect(&:url)
    end
  end
end