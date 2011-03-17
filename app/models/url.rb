class Url

  include HTTParty
  format :json

  def self.shorten(s, options={})
    headers('Content-Type' => 'application/json')
    response = post("https://www.googleapis.com/urlshortener/v1/url?key=#{GOOGLE_SHORTENER_API_KEY}",
                    :body => "{'longUrl' : '#{s}'}")
    if response.response.is_a?(Net::HTTPOK)
      response['id']
    else
      s
    end
  rescue Exception => e
    s
  end

  def self.expand(s, options={})
    headers('Content-Type' => 'application/json')
    response = get("https://www.googleapis.com/urlshortener/v1/url?key=#{GOOGLE_SHORTENER_API_KEY}&shortUrl=#{s}")
    if response.response.is_a?(Net::HTTPOK)
      response['longUrl']
    else
      s
    end
  rescue Exception => e
    s
  end

end