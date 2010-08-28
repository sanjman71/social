require 'test_helper'

class ZipTest < ActiveSupport::TestCase

  should belong_to :state
  should belong_to :timezone
  should have_many :locations
  
  def setup
    @us   = Factory(:us)
    @il   = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @ny   = Factory(:state, :name => "New York", :code => "NY", :country => @us)
  end
  
  context "zip" do
    context "valid zip 60654" do
      setup do
        @zip = Zip.create(:name => "60654", :state => @il)
        assert @zip.valid?
      end

      should "have to_s method return 60654" do
        assert_equal "60654", @zip.to_s
      end
      
      should "have to_param method return 60654" do
        assert_equal "60654", @zip.to_param
      end
    end
    
    should "not create with invalid zip" do
      @zip = Zip.create(:name => "1111", :state => @il)
      assert_false @zip.valid?
    end
  end
end