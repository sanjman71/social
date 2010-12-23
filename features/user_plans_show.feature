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
    Given a locationship exists with user: user "chicago_guy", location: location "Chicago Starbucks", todo_checkins: "1", todo_at: "#{10.days.ago}", todo_expires_at: "#{10.days.ago+7.days}"
    And a locationship exists with user: user "chicago_guy", location: location "Chicago Lavazza", todo_checkins: "1"
    And I am logged in as "chicago_guy"
    When I go to chicago_guy's plans page
    Then I should see "Chicago Lavazza" within "div#todos div.location:first-child"
    And I should see "7 days left" within "div.location"
    And I should see "Chicago Starbucks" within "div#todos"
    And I should see "Expired"

  