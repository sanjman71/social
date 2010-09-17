require 'test_helper'

class AlertTest < ActiveSupport::TestCase

  should "require level" do
    @alert = Alert.create
    assert @alert.errors[:level]
    @alert = Alert.create(:level => 'foo')
    assert @alert.errors[:level]
    @alert = Alert.create(:level => 'debug')
    assert @alert.errors[:level].blank?
  end

end