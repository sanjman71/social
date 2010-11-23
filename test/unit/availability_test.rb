require 'test_helper'

class AvailabilityTest < ActiveSupport::TestCase

  context "create" do
    should "set default start_at and end_at values when now is set" do
      @user = User.create!(:name => Random.firstname, :handle => Random.alphanumeric,
                           :availability_attributes => {:now => 1})
      assert_true @user.reload.availability.now
      assert_true @user.reload.availability.now?
    end
  end
  
  context "available now" do
    should "not be available when no availability object" do
      @user = User.create!(:name => Random.firstname, :handle => Random.alphanumeric)
      assert_false @user.availability.try(:now?)
    end

    should "reset now to false after end_at time passes" do
      @user = User.create!(:name => Random.firstname, :handle => Random.alphanumeric,
                            :availability_attributes => {:now => 1})
      assert_true @user.reload.availability.now
      Timecop.travel(Time.now+Availability.default_now_hours+1.minute) do
        @user.save
        assert_false @user.availability.now?
        assert_nil @user.availability.start_at
        assert_nil @user.availability.end_at
      end
    end

    should "reset start_at, end_at values when now set to false" do
      @user = User.create!(:name => Random.firstname, :handle => Random.alphanumeric,
                            :availability_attributes => {:now => 1})
      assert_true @user.reload.availability.now
      @user.availability.update_attribute(:now, false)
      assert_false @user.availability.now?
      assert_nil @user.availability.start_at
      assert_nil @user.availability.end_at
    end
  end
  
end