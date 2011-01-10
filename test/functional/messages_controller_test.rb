require 'test_helper'

class MessagesControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  context "routes" do
    should route(:post, "/messages.json").to(:controller => 'messages', :action => 'create', :format => 'json')
  end

end