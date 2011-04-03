Feature: User Learn More
  As a user
  I want to learn more about other users

  # Background:
  #   Given a city: "Chicago" should exist with name: "Chicago"
  #   And a user "chicago_guy" exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1", points: "100"
  #   And user "chicago_guy" has email "chicago_guy@gmail.com"
  #   And a user "chicago_gal" exists with handle: "chicago_gal", gender: "Female", orientation: "Straight", city: city "Chicago", member: "1", points: "100"
  #   And a location "Starbucks" exists with name: "Starbucks", city_state: "Chicago:IL", lat: "41.8781136", lng: "-87.6297982"
  # 
  # @checkin @email @javascript
  # Scenario: A user should receive an email when they want to learn more about another user and checkin to one of their locations
  #   Given I am logged in as "chicago_guy"
  #   And a checkin exists with user: user "chicago_gal", location: location "Starbucks", checkin_at: "#{3.days.ago}", source_id: "1", source_type: "foursquare"
  #   And I go to chicago_gal's profile page
  #   And I follow "Learn More"
  #   And I press "Ok" within "div#dialog-profile-learn-more"
  #   And a checkin exists with user: user "chicago_guy", location: location "Starbucks", checkin_at: "#{1.hour.ago}", source_id: "1", source_type: "foursquare"
  #   # process jobs twice, since the first set adds another job
  #   And the resque jobs are processed
  #   And the resque jobs are processed
  # 
  #   Then "chicago_guy@gmail.com" should receive an email with subject "Outlately: You wanted to know more about chicago_gal..."
  #   And I open the email with subject "Outlately: You wanted to know more about chicago_gal..."
  #   And I should see "You and chicago_gal have 0 mutual friends" in the email body
  # 
  #   # another checkin should not trigger another email
  #   Given a clear email queue
  #   And the resque jobs are reset
  #   And a checkin exists with user: user "chicago_guy", location: location "Starbucks", checkin_at: "#{30.minutes.ago}", source_id: "2", source_type: "foursquare"
  #   And the resque jobs are processed
  #   And the resque jobs are processed
  #   Then "chicago_guy@gmail.com" should receive no email with subject "Outlately: You wanted to know more about chicago_gal..."
    
