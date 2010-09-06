case Rails.env
when 'development', 'test'
  GOOGLE_MAPS_KEY = "ABQIAAAAomTSMjVMlOfQaldkZBqMBBQf8Rzy2ZcACVxYDKeiU5AgHyYWGBR1k1cjUQ1lJBbPUXEoFNRuqKCrgA"
when 'production'
  GOOGLE_MAPS_KEY = "ABQIAAAAomTSMjVMlOfQaldkZBqMBBRB5sHKHbBpNwpljJacvnA0UY36WxRxrGHm0Q6efneLmObbv1mf2zsWDw"
end
