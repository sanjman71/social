Then /^I fill in "([^"]*)" with tomorrow$/ do |field|
  tomorrow = 1.day.from_now.to_s(:date_ddmmyyyy)
  And %{I fill in "#{field}" with "#{tomorrow}"}
end

# create user suggestion
Given /^a suggestion exists for user(?:s) "([^"]*)" and "([^"]*)" at location "([^"]*)"$/ do |handle1, handle2, loc_name|
  user1       = User.find_by_handle!(handle1)
  user2       = User.find_by_handle!(handle2)
  location    = Location.find_by_name!(loc_name)
  options     = Hash[:party1_attributes => {:user => user1}, :party2_attributes => {:user => user2},
                     :location => location, :when => 'next week']
  suggestion  = Suggestion.create(options)
end

# schedule user suggestion
Given /^"([^"]*)" schedules (his|her) suggestion with "([^"]*)" "([^"]*)"$/ do |handle1, x, handle2, date|
  user1         = User.find_by_handle!(handle1)
  user2         = User.find_by_handle!(handle2)
  suggestion    = user1.suggestions.select{ |s| s.other_party(user1).user_id == user2.id }.first
  raise Exception, "missing suggestion" if suggestion.blank?
  scheduled_at  = eval(date)
  party         = suggestion.my_party(user1)
  suggestion.party_schedules(party, :scheduled_at => scheduled_at)
  suggestion.party_confirms(party, :message => :keep, :event => 'schedule')
end

