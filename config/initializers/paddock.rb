include Paddock

Paddock(Rails.env) do
  disable :import_friends, :in => [:development]
  enable :fill_home_checkins, :in => [:development]
  enable :send_checkin_matches
  disable :user_suggestions
  disable :realtime_checkin_matches
  disable :daily_checkin_matches
  # enable  :phone_system,  :in => [:development, :test]
  # enable  :raptor_fences
end
