require 'test_helper'

class AvailabilityTest < ActiveSupport::TestCase

  context "create" do
    should "start with availability 1 and default time values" do
      @user = User.create!(:name => Random.firstname, :handle => Random.alphanumeric,
                           :availability_attributes => {:now => 1})
      assert_true @user.reload.availability.now
      assert_true @user.reload.availability.now?
      assert @user.availability.start_at
      assert @user.availability.end_at
    end

    should "start with availability true and default time values" do
      @user = User.create!(:name => Random.firstname, :handle => Random.alphanumeric,
                           :availability_attributes => {:now => true})
      assert_true @user.reload.availability.now
      assert_true @user.reload.availability.now?
      assert @user.availability.start_at
      assert @user.availability.end_at
    end

    should "start with availability '0'" do
      @user = User.create!(:name => Random.firstname, :handle => Random.alphanumeric,
                           :availability_attributes => {:now => '0'})
      assert_false @user.reload.availability.now
      assert_nil @user.availability.start_at
      assert_nil @user.availability.end_at
    end

    should "start with availability false" do
      @user = User.create!(:name => Random.firstname, :handle => Random.alphanumeric,
                           :availability_attributes => {:now => false})
      assert_false @user.reload.availability.now
      assert_nil @user.availability.start_at
      assert_nil @user.availability.end_at
    end
  end
  
  context "available now" do
    should "return false when no availability object" do
      @user = User.create!(:name => Random.firstname, :handle => Random.alphanumeric)
      assert_false @user.availability.try(:now?)
    end

    should "automatically reset now to false after end_at time passes" do
      @user = User.create!(:name => Random.firstname, :handle => Random.alphanumeric,
                           :availability_attributes => {:now => 1})
      assert_true @user.reload.availability.now
      # travel to tomorrow
      Timecop.travel(Time.zone.now.end_of_day+1.minute) do
        @user.save
        assert_false @user.availability.now?
        assert_nil @user.availability.start_at
        assert_nil @user.availability.end_at
      end
    end
  end
  
end