require 'test_helper'

class CityTest < ActiveSupport::TestCase

  should belong_to :state
  should belong_to :timezone
  should have_many :neighborhoods
  should have_many :locations

  context "city with state" do
    context "chicago" do
      setup do
        @chicago = cities(:chicago)
      end
      
      should "have to_param method return chicago" do
        assert_equal "chicago", @chicago.to_param
      end
      
      should "have to_s method return Chicago" do
        assert_equal "Chicago", @chicago.to_s
      end

      should "have city_state == Chicago, IL" do
        assert_equal "Chicago, IL", @chicago.city_state
      end
    end

    context "new york" do
      setup do
        @new_york = cities(:new_york)
      end

      should "have to_param method return new-york" do
        assert_equal "new-york", @new_york.to_param
      end
    end
  end

  context "city with country" do
    setup do
      @fr    = Country.create!(:name => 'France', :code => 'FR')
      @paris = City.create!(:name => 'Paris', :country => @fr)
    end

    should "have city_state == Paris, FR" do
      assert_equal "Paris, FR", @paris.city_state
    end
  end
end
