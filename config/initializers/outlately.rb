ADMIN_FACEBOOK_IDS  = ['633015812']
AUTH_TOKEN          = "5e722026ea70e6e497815ef52f9e73c5ddb8ac26"

case Rails.env
when 'development'
  IMPORT_FRIENDS    = 0
  FRIEND_LIMIT      = 10
else
  IMPORT_FRIENDS    = 1
  FRIEND_LIMIT      = 50
end