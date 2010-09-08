class CheckinLog < ActiveRecord::Base
  belongs_to  :user
  
  scope       :error, where(:state => 'error')
end