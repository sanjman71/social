include Paddock

Paddock(Rails.env) do
  disable :import_friends, :in => [:development]
  # enable  :phone_system,  :in => [:development, :test]
  # enable  :raptor_fences
end