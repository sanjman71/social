case Rails.env
when 'development', 'test'
  GOOGLE_MAPS_KEY = "ABQIAAAAiuumaQ8zCrVmDaXTvnOnxRQSl1GINAMAsdLCp3TGJWdlrkoABBQ0WmpCkxE8nTeVlJLxz8rVm5FSqw"
when 'production'
  GOOGLE_MAPS_KEY = "ABQIAAAAomTSMjVMlOfQaldkZBqMBBQCvIYwEwIoOiUyef86MtXNA8n6SxSIIcOVGTPPrLzSanErRbvLcnQy1g"
end
