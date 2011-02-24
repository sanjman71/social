class Url

  include HTTParty
  format :json

  # shorten url except in the specified environment
  def self.shorten_except_env(s, env)
    return s if Rails.env == env
    shorten(s)
  end

  def self.shorten(s, options={})
    headers('Content-Type' => 'application/json')
    response = post("https://www.googleapis.com/urlshortener/v1/url?key=#{GOOGLE_SHORTENER_API_KEY}",
                    :body => "{'longUrl' : '#{s}'}")
    if response.response.is_a?(Net::HTTPOK)
      response['id']
    else
      nil
    end
  rescue Exception => e
    nil
  end

end