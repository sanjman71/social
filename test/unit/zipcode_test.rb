require 'test_helper'

class ZipcodeTest < ActiveSupport::TestCase

  should belong_to :state
  should belong_to :timezone
  should have_many :locations

  def setup
    @il   = states(:il)
    @ny   = states(:ny)
  end
  
  context "zip" do
    context "valid zip 60654" do
      setup do
        @zip = Zipcode.create!(:name => "60601", :state => @il)
      end

      should "have to_s method return 60601" do
        assert_equal "60601", @zip.to_s
      end
      
      should "have to_param method return 60601" do
        assert_equal "60601", @zip.to_param
      end
    end

    should "not create with invalid zip" do
      @zip = Zipcode.create(:name => "1111", :state => @il)
      assert @zip.invalid?
    end
  end
end