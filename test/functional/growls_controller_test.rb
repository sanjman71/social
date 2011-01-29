require 'test_helper'

class GrowlsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    @user1 = Factory.create(:user, :handle => 'User1')
  end

  context "index" do
    should "return no growl message when flash[:growls] is empty" do
      sign_in @user1
      set_beta
      get :index, :format => 'json'
      assert_equal "application/json", @response.content_type
      @json = JSON.parse(@response.body)
      # should have 0 growl messages
      assert_equal 1, @json.size
      assert @json['growls'].empty?
    end
  
    should "return flash growl message when flash[:growls] has stuff" do
      # set flash growl message
      @growl = [{:message => 'growl message'}]
      ActionDispatch::Flash::FlashHash.any_instance.stubs(:[]).returns(nil)
      ActionDispatch::Flash::FlashHash.any_instance.stubs(:[]).with(:growls).returns(@growl)
      sign_in @user1
      set_beta
      get :index, :format => 'json'
      assert_equal "application/json", @response.content_type
      @json = JSON.parse(@response.body)
      # should have 1 growl message
      assert_equal 1, @json.size
      assert_equal [{"message"=>"growl message"}], @json['growls']
    end
  end
end