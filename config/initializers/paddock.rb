include Paddock

Paddock(Rails.env) do
  disable :import_friends, :in => [:development]
  disable :send_checkin_matches, :in => [:production]
  # enable  :phone_system,  :in => [:development, :test]
  # enable  :raptor_fences
end
