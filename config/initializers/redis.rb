case Rails.env
when 'production'
  OUTLATELY_REDIS_DB = 1
else
  OUTLATELY_REDIS_DB = 2
end