ADMIN_FACEBOOK_IDS = ['633015812']

case Rails.env
when 'development'
  IMPORT_FRIENDS    = 0
  FRIEND_LIMIT      = 10
else
  IMPORT_FRIENDS    = 1
  FRIEND_LIMIT      = 50
end