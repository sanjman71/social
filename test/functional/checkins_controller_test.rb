require 'test_helper'

class CheckinsControllerTest < ActionController::TestCase

  context "routes" do
    should route(:get, '/checkins/poll').to(:controller => 'checkins', :action => 'poll')
    should route(:get, '/users/1/checkins').to(:controller => 'checkins', :action => 'index', :user_id => '1')
    should route(:get, "/users/1/checkins/geo:1.23..-77.89/radius:50").
      to(:controller => 'checkins', :action => 'index', :geo => 'geo:1.23..-77.89', :radius => 'radius:50',
         :user_id => '1')
    should route(:get, "/users/1/checkins/city:chicago/radius:50").
      to(:controller => 'checkins', :action => 'index', :city => 'city:chicago', :radius => 'radius:50',
         :user_id => '1')
  end

end
