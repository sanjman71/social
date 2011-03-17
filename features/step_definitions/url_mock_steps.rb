if Rails.env == 'test'
  class Url
    def self.shorten(s, options={})
      s
    end
  end
end