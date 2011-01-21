require 'test_helper'

class AdminControllerTest < ActionController::TestCase
  context "routes" do
    should route(:get, "/admin").to(:controller => 'admin', :action => 'index')
    should route(:get, "/admin/checkins_chart").to(:controller => 'admin', :action => 'checkins_chart')
    should route(:get, "/admin/invites_chart").to(:controller => 'admin', :action => 'invites_chart')
    should route(:get, "/admin/tags_chart").to(:controller => 'admin', :action => 'tags_chart')
    should route(:get, "/admin/users_chart").to(:controller => 'admin', :action => 'users_chart')
    should route(:get, "/admin/badges").to(:controller => 'badges', :action => 'index')
  end
end
