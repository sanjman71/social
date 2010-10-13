require 'test_helper'

class GrowlsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    @user1 = Factory.create(:user, :handle => 'User1')
  end

  context "index" do
    should "return test message" do
      sign_in @user1
      set_beta
      get :index, :format => 'json'
      assert_equal "application/json", @response.content_type
      @json = JSON.parse(@response.body)
      # should have 1 growl message
      assert_equal 1, @json.size
      assert_equal 'growl message', @json[0]['message']
    end
  end
end