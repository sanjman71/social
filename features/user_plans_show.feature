Feature: User's planned checkins
  As as user, I want to see my planned checkins and receive notifications for expiring and completed plans
  
  Background:
    Given a city: "Chicago" should exist with name: "Chicago"
    And a state: "IL" should exist with code: "IL"
    And a user exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    Then a user "chicago_guy" should exist with handle: "chicago_guy"
    And a location exists with name: "Chicago Starbucks", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    Then a location "Chicago Starbucks" should exist with name: "Chicago Starbucks"
    And a location exists with name: "Chicago Lavazza", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    Then a location "Chicago Lavazza" should exist with name: "Chicago Lavazza"

  @javascript
  Scenario: User should see their planned checkins, most recent first, and expired plans marked clearly
    Given a locationship exists with user: user "chicago_guy", location: location "Chicago Starbucks", todo_checkins: "1", todo_at: "#{10.days.ago}"
    And a locationship exists with user: user "chicago_guy", location: location "Chicago Lavazza", todo_checkins: "1", todo_at: "#{Time.zone.now}"
    And I am logged in as "chicago_guy"
    When I go to chicago_guy's plans page
    Then I should see "Chicago Lavazza" within "div#todos div.location:first-child"
    And I should see "7 days left" within "div.location"
    And I should see "Chicago Starbucks"
    And I should see "Expired"

  Scenario: User should receive an email a few days before a planned checkin expires
    Given a locationship exists with user: user "chicago_guy", location: location "Chicago Starbucks", todo_checkins: "1", todo_at: "#{5.days.ago+1.minute}"
    And user "chicago_guy" has email "chicago_guy@outlately.com"
    And I am logged in as "chicago_guy"
    And checkin todo reminders are sent
    Then "chicago_guy@outlately.com" should receive an email with subject "Your planned checkin is about to expire"
    When I open the email
    Then I should see "Time is running out to checkin at Chicago Starbucks. You get 50 bucks for doing it!" in the email body

  Scenario: User should receive an email after checking in to a non-expired planned location
    Given a locationship exists with user: user "chicago_guy", location: location "Chicago Starbucks", todo_checkins: "1", todo_at: "#{3.days.ago}"
    And user "chicago_guy" has email "chicago_guy@outlately.com"
    And I am logged in as "chicago_guy"
    And a checkin exists with user: user "chicago_guy", location: location "Chicago Starbucks", checkin_at: "#{3.hours.ago}", source_id: "1", source_type: "foursquare"
    And the delayed jobs are processed
    Then "chicago_guy@outlately.com" should receive an email with subject "You checked in at a planned location!"
    When I open the email with subject "You checked in at a planned location!"
    Then I should see "You said you'd checkin at Chicago Starbucks and you did. That checkin got you 50 bucks." in the email body

  Scenario: User should receive an email after a planned location expires

  