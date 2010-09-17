class Alert < ActiveRecord::Base
  validates   :user_id, :presence => true
  validates   :level, :presence => true, :inclusion => {:in => %w(notice debug error)}
  validates   :subject, :presence => true
  validates   :message, :presence => true
  
  belongs_to  :user
  belongs_to  :sender, :class_name => 'User'
end