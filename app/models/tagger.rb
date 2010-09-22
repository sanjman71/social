# coding: utf-8
class Tagger
  
  # normalize the string into a set of tags
  # e.g 'Nightlife:Brewery / Microbrewery', 'Food:Café'
  def self.normalize(s, options={})
    begin
      tags = s.split(':').collect do |s1|
        s1.split('/').collect do |s2|
          s2.strip.downcase.gsub(/é/, 'e')
        end
      end.flatten.sort
    rescue
      return []
    end
  end
end