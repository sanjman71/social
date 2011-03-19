Feature: Join in on a planned checkin
  As a user I want to be able to join another user when I see they have a planned checkin
  
  # deprecated
  # @javascript @todo @email
  # Scenario: User joins other planned checkins from the home page with the 'Join Me' button
  #   Given a city: "Chicago" should exist with name: "Chicago"
  #   And a state: "IL" should exist with code: "IL"
  #   And a user "chicago_guy" exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
  #   And user "chicago_guy" has email "chicago_guy@outlately.com"
  #   And a user "chicago_gal" exists with handle: "chicago_gal", gender: "Female", orientation: "Straight", city: city "Chicago", member: "1"
  #   And user "chicago_gal" has email "chicago_gal@outlately.com"
  #   And a location "Chicago Starbucks" exists with name: "Chicago Starbucks", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
  #   And a planned_checkin exists with user: user "chicago_gal", location: location "Chicago Starbucks", planned_at: "#{3.days.ago}", going_at: "#{1.day.from_now}"
  #   And I am logged in as "chicago_guy"
  #   And sphinx is indexed
  #   When I go to the home page
  #   Then I should see "Everyone" within "ul#social-stream-nav li.active"
  #   And I should see "chicago_gal" within "ul#social-stream"
  #   And I should see "plans on going in 1 day"
  # 
  #   And I follow "Join Me"
  #   Then I should see "If you go there within 7 days"
  # 
  #   And the resque jobs are processed
  #   Then "chicago_gal@outlately.com" should receive an email with subject "Outlately: chicago_guy is planning on joining you..."
  #   And "chicago_gal@outlately.com" opens the email with subject "Outlately: chicago_guy is planning on joining you..."
  #   Then I should see "chicago_guy is also going to 'Chicago Starbucks' tomorrow." in the email body
    