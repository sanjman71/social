require 'test_helper'

class UserOauthTest < ActiveSupport::TestCase

  def setup
    @user1 = User.create!(:name => "User 1", :handle => 'user1')
  end

  context "facebook oauth create" do
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
      # should add user points for oauth
      assert_equal 5, @user1.reload.points
      # should add linked account alert
      assert_equal 1, @user1.reload.alerts.count
      # should queue delayed job to import facebook friends
      assert_equal 1, match_delayed_jobs(/async_import_friends/)
      friend_data = YAML::load_file("#{Rails.root}/test/data/facebook_friends.txt")
      # stub friends data
      FacebookClient.any_instance.stubs(:friends).returns(friend_data)
      FacebookClient.any_instance.stubs(:user).returns(Hash['gender' => 'male', 'id' => 'fbid',
                                                            'link' => "http://www.facebook.com/handle"])
      FacebookClient.any_instance.stubs(:checkins).returns(Hash['data' => [{}]])
      
      work_off_delayed_jobs(/async_import_friends/)
      # should add 3 friends
      assert_equal 3, @user1.reload.friends.size
    end
  end

  context "foursquare oauth create" do
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
      # should add user points for oauth
      assert_equal 5, @user1.reload.points
      # should add linked account alert
      assert_equal 1, @user1.reload.alerts.count
    end
  end

  context "twitter oauth create" do
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
      # should add user points for oauth
      assert_equal 5, @user1.reload.points
      # should add linked account alert
      assert_equal 1, @user1.reload.alerts.count
    end
  end
end