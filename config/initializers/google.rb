case Rails.env
when 'production'
  GOOGLE_ACCOUNT = 'UA-21006913-1'
else
  GOOGLE_ACCOUNT = 'UA-21006913-z'
end