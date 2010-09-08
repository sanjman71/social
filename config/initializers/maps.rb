case Rails.env
when 'development', 'test'
  GOOGLE_MAPS_KEY = "ABQIAAAAomTSMjVMlOfQaldkZBqMBBT_3IJgYfW4oPtWVUONtg01ZmXmXBRZ7ADW9bvU4n_rpCGJKL4ao3jIFg"
when 'production'
  GOOGLE_MAPS_KEY = "ABQIAAAAomTSMjVMlOfQaldkZBqMBBQCvIYwEwIoOiUyef86MtXNA8n6SxSIIcOVGTPPrLzSanErRbvLcnQy1g"
end
