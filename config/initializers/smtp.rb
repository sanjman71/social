ActionMailer::Base.smtp_settings = {  
  :address              => "smtp.gmail.com",  
  :port                 => 587,
  :domain               => "jarna.com",
  :user_name            => "outlately@jarna.com",
  :password             => "outlately",
  :authentication       => "plain",
  :enable_starttls_auto => true,
}