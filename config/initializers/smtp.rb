ActionMailer::Base.smtp_settings = {  
  :address              => "smtp.gmail.com",  
  :port                 => 587,
  :domain               => "jarna.com",
  :user_name            => "outlately",
  :password             => "outlately",
  :authentication       => "plain",
  :enable_starttls_auto => true,
}