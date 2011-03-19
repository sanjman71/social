Feature: Emails are sent when a social dna badge is added to a user
  As a user
  I want to be notified when a social dna badge is added

  Scenario:
    Given a city: "Chicago" should exist with name: "Chicago"
    And a state: "IL" should exist with code: "IL"
    And a user "chicago_guy" exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1", points: "0"
    And user "chicago_guy" has email "chicago_guy@outlately.com"
    And a location "Starbucks" exists with name: "Starbucks", city_state: "Chicago:IL", lat: "41.8781136", lng: "-87.6297982"
    And location "Starbucks" is tagged with "coffee"
    And a checkin exists with user: user "chicago_guy", location: location "Starbucks", checkin_at: "#{3.hours.ago}", source_id: "1", source_type: "foursquare"
    And a badge exists with name: "Caffeine Junkie", tagline: "Mainlines Espresso", regex: "coffee"
    And user badge discovery is run
    And the resque jobs are processed
    Then "chicago_guy@outlately.com" should receive an email with subject "Outlately: Your Social DNA has been updated with a new badge..."

    And I open the email with subject "Outlately: Your Social DNA has been updated with a new badge..."
    Then I should see "You have been awarded the 'Caffeine Junkie' badge.  Keep up the checkins." in the email body
    And I should see "utm_campaign" in the email body
    And I am logged in as "chicago_guy"
    And I follow "here" in the email
    Then I should be on the profile page
    