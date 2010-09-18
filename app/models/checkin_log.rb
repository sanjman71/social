class CheckinLog < ActiveRecord::Base
  belongs_to  :user #, :touch => true
  # after_save  :after_save_callback

  scope       :error, where(:state => 'error')

  protected
  
  def after_save_callback
    if user.reload.checkins_count < Checkin.min_checkins_for_suggestion
      puts "*** checkin log saved, sending alert"
      user.alerts.create(:level => 'notice', :subject => 'checkins', :message => 'Checkin a few more times')
    end
  end
end