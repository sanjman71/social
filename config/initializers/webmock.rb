if ['development', 'test'].include?(Rails.env)
  WebMock.allow_net_connect!
end