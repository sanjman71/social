# coding: utf-8
require 'test_helper'

class TaggerTest < ActiveSupport::TestCase

  should "normalize Food:Café" do
    tags = Tagger.normalize("Food:Café")
    assert_equal ['cafe', 'food'], tags.sort
  end
  
  should "normalize Nightlife:Brewery / Microbrewery" do
    tags = Tagger.normalize("Nightlife:Brewery / Microbrewery")
    assert_equal ['brewery', 'microbrewery', 'nightlife'], tags.sort
  end
end