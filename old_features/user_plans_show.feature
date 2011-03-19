Feature: User's planned checkins
  As as user, I want to see my planned checkins and receive notifications for expiring and completed planned checkins

  Background:
    Given a city: "Chicago" should exist with name: "Chicago"
    And a state: "IL" should exist with code: "IL"
    And a user "chicago_guy" exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And a location "Chicago Starbucks" exists with name: "Chicago Starbucks", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And a location "Chicago Lavazza" exists with name: "Chicago Lavazza", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"

  @javascript
  Scenario: User should see their planned checkins, most recent first
    Given a planned_checkin exists with user: user "chicago_guy", location: location "Chicago Starbucks", planned_at: "#{3.days.ago}"
    And a planned_checkin exists with user: user "chicago_guy", location: location "Chicago Lavazza"
    And 5 days have passed
    And planned checkins are expired
    And I am logged in as "chicago_guy"
    When I go to chicago_guy's plans page
    Then I should see "Chicago Lavazza" within "div#todos div.location:first-child"
    And I should see "2 days left" within "div.location"
    And I should not see "Chicago Starbucks" within "div#todos"

  