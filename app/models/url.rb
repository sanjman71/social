class Url

  include HTTParty
  format :json

  def self.shorten(s)
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