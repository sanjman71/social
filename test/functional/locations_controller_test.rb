require 'test_helper'

class LocationsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  context "routes" do
    should route(:get, "/locations/geo:1.23..-77.89/radius:50").to(
      :controller => 'locations', :action => 'index', :geo => 'geo:1.23..-77.89', :radius => 'radius:50')
  end

end