require 'test_helper'

class UserOauthTest < ActiveSupport::TestCase

  def setup
    WebMock.allow_net_connect!
    @user1  = User.create!(:name => "User 1", :handle => 'user1')
  end

  context "facebook oauth create" do
    should "create oauth, set member, set user facebook id + facebook photo, import facebook friends" do
      # parse json into a hash
      json_data     = File.open("#{Rails.root}/test/data/facebook_user.json")
      user_data     = Crack::JSON.parse(File.read(json_data))
      credentials   = {'token' => "1"}
      User.find_for_facebook_oauth(credentials, user_data, @user1)
      # should set user facebook id
      assert @user1.facebook_id
      # should set user member flag
      assert @user1.member?
      # should create user facebook oauth
      assert_equal 1, @user1.oauths.facebook.count
      # should set handle to 'First L'
      assert_equal "Sanjay K.", @user1.reload.handle
      # should create user facebook photo
      assert_equal 1, @user1.photos.facebook.count
      assert_equal [1], @user1.photos.facebook.collect(&:priority)
      assert_equal ["https://graph.facebook.com/633015812/picture?type=square"], @user1.photos.facebook.collect(&:url)
      # should add user points for oauth
      assert_equal 5, @user1.reload.points
      # stub friends data
      friend_data = YAML::load_file("#{Rails.root}/test/data/facebook_friends.txt")
      FacebookClient.any_instance.stubs(:friends).returns(friend_data)
      FacebookClient.any_instance.stubs(:user).returns(Hash['gender' => 'male', 'id' => 'fbid',
                                                            'link' => "http://www.facebook.com/handle"])
      FacebookClient.any_instance.stubs(:checkins).returns(Hash['data' => [{}]])
      # should queue delayed job to import facebook friends
      assert_equal 1, match_delayed_jobs(/async_import_friends/)
      work_off_delayed_jobs(/async_import_friends/)
      # should create 3 users and add 3 friends, with formatted handles and gender
      assert_equal 3, @user1.reload.friends.size
      assert_equal ["Praveen S.", "Adam M.", "Nevin K."], @user1.reload.friends.collect(&:handle)
      assert_equal [2, 2, 2], @user1.reload.friends.collect(&:gender)
    end
    
    should "add friends without creating users if they already exist" do
      # parse json into a hash
      json_data     = File.open("#{Rails.root}/test/data/facebook_user.json")
      user_data     = Crack::JSON.parse(File.read(json_data))
      credentials   = {'token' => "1"}
      User.find_for_facebook_oauth(credentials, user_data, @user1)
      # add user, who will be friended, to the system
      @adam = User.create!(:handle => "Adam M.", :facebook_id => "620186040", :gender => 2)
      # stub friends data
      friend_data = YAML::load_file("#{Rails.root}/test/data/facebook_friends.txt")
      FacebookClient.any_instance.stubs(:friends).returns(friend_data)
      FacebookClient.any_instance.stubs(:user).returns(Hash['gender' => 'male', 'id' => 'fbid',
                                                            'link' => "http://www.facebook.com/handle"])
      FacebookClient.any_instance.stubs(:checkins).returns(Hash['data' => [{}]])
      # should queue delayed job to import facebook friends
      assert_equal 1, match_delayed_jobs(/async_import_friends/)
      work_off_delayed_jobs(/async_import_friends/)
      # should create 2 users and add 3 friends, all with formatted handles
      assert_equal 3, @user1.reload.friends.size
      assert_equal ["Adam M.", "Praveen S.", "Nevin K."], @user1.reload.friends.collect(&:handle)
      assert_equal [2, 2, 2], @user1.reload.friends.collect(&:gender)
    end

    should "not re-add friends during import friends process" do
      # parse json into a hash
      json_data     = File.open("#{Rails.root}/test/data/facebook_user.json")
      user_data     = Crack::JSON.parse(File.read(json_data))
      credentials   = {'token' => "1"}
      User.find_for_facebook_oauth(credentials, user_data, @user1)
      # add user as friend
      @adam = User.create!(:handle => "Adam M.", :facebook_id => "620186040", :gender => 2)
      @user1.friendships.create!(:friend => @adam)
      assert_equal ["Adam M."], @user1.reload.friends.collect(&:handle)
      # stub friends data
      friend_data = YAML::load_file("#{Rails.root}/test/data/facebook_friends.txt")
      FacebookClient.any_instance.stubs(:friends).returns(friend_data)
      FacebookClient.any_instance.stubs(:user).returns(Hash['gender' => 'male', 'id' => 'fbid',
                                                            'link' => "http://www.facebook.com/handle"])
      FacebookClient.any_instance.stubs(:checkins).returns(Hash['data' => [{}]])
      # should queue delayed job to import facebook friends
      assert_equal 1, match_delayed_jobs(/async_import_friends/)
      work_off_delayed_jobs(/async_import_friends/)
      # should create 2 users and add 2 friends
      assert_equal 3, @user1.reload.friends.size
      assert_equal ["Adam M.", "Praveen S.", "Nevin K."], @user1.reload.friends.collect(&:handle)
    end
  end

  context "foursquare oauth create" do
    should "create oauth, set user foursquare id, foursquare photo" do
      # parse json into a hash
      json_data     = File.open("#{Rails.root}/test/data/foursquare_user.json")
      user_data     = Crack::JSON.parse(File.read(json_data))['user']
      credentials   = {'token' => "1", 'secret' => 'xyz'} # note: foursquare currently uses oauth1 so a secret is passed in
      User.find_for_foursquare_oauth(credentials, user_data, @user1)
      # should create user foursquare oauth
      assert_equal 1, @user1.oauths.foursquare.count
      # should set user foursquare id
      assert @user1.foursquare_id
      # should set user foursquare photo
      assert_equal 1, @user1.photos.foursquare.count
      assert_equal [3], @user1.photos.foursquare.collect(&:priority)
      assert_equal ["http://foursquare.com/img/blank_boy.png"], @user1.photos.foursquare.collect(&:url)
      # should add user points for oauth
      assert_equal 5, @user1.reload.points
    end
  end

  context "twitter oauth create" do
    should "create oauth, set user twitter id, twitter photo" do
      # parse json into a hash
      json_data     = File.open("#{Rails.root}/test/data/twitter_user.json")
      user_data     = Crack::JSON.parse(File.read(json_data))
      credentials   = {'token' => "1"}
      User.find_for_twitter_oauth(credentials, user_data, @user1)
      # should create user twitter oauth
      assert_equal 1, @user1.oauths.twitter.count
      # should set user twitter id
      assert @user1.twitter_id
      # should set user twitter photo
      assert_equal 1, @user1.photos.twitter.count
      assert_equal [5], @user1.photos.twitter.collect(&:priority)
      assert_equal ["http://s.twimg.com/a/1284949838/images/default_profile_0_normal.png"], @user1.photos.twitter.collect(&:url)
      # should add user points for oauth
      assert_equal 5, @user1.reload.points
    end
  end
end