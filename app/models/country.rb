class Country < ActiveRecord::Base
  validates     :name, :uniqueness => true
  validates     :code, :presence => true, :uniqueness => true
  has_many      :states
  has_many      :cities
  has_many      :locations
  
  include NameParam

  attr_accessible   :name, :code

  def self.default
    @@country ||= self.us
  end

  def self.us
    Country.find_or_create_by_code(:code => "US", :name => 'United States')
  end

  def to_param
    self.code.downcase
  end

end