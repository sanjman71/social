Social::Application.config.middleware.use ExceptionNotifier,
  :email_prefix => "[Outlate.ly #{Rails.env}] ",
  :sender_address => %{"Outlate.ly" <outlately@jarna.com>},
  :exception_recipients => %w{sanjay@jarna.com}