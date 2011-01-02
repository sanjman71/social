Feature: Add Bucks
  As a user I want to add bucks to my account

  @javascript
  Scenario: User clicks Get more bucks to add points to their account
    Given a city: "Chicago" should exist with name: "Chicago"
    And a user exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1", points: "0"
    And sphinx is indexed
    And I am logged in as "chicago_guy"
    When I go to the home page
    And I press "Get more bucks"
    Then I should see "100" within "span#user_points"
