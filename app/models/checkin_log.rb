class CheckinLog < ActiveRecord::Base
  belongs_to  :user #, :touch => true

  scope       :error, where(:state => 'error')

end