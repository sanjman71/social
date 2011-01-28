include Paddock

Paddock(Rails.env) do
  disable :import_friends, :in => [:development]
  enable :send_checkin_matches
  disable :user_suggestions
  # enable  :phone_system,  :in => [:development, :test]
  # enable  :raptor_fences
end
