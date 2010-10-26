require 'test_helper'

class CheckinsControllerTest < ActionController::TestCase

  context "routes" do
    should route(:get, 'users/1/checkins').to(:controller => 'checkins', :action => 'index', :user_id => '1')
    should route(:get, 'checkins/facebook/12345/count').to(
      :controller => 'checkins', :action => 'count', :source => 'facebook', :source_id => '12345')
  end

end
