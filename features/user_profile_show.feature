Feature: User Profile
  I want to see user profiles

  @javascript
  Scenario: Visiting a user profile costs 10 points
    Given a city: "Chicago" should exist with name: "Chicago"
    And a user exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1", points: "100"
    And a user exists with handle: "chicago_gal", gender: "Female", orientation: "Straight", city: city "Chicago", member: "1", points: "100"
    And I am logged in as "chicago_guy"
    And sphinx is indexed
    When I go to chicago_gal's profile page
    Then I should see "90" within "div#my-points div#screen"
