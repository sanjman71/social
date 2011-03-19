Feature: Add shouts
  In order to encourage activity and stickiness
  As a user
  I want to be able to comment on locations

  @javascript
  Scenario: User adds a shout by looking up a place
    Given a city: "Chicago" should exist with name: "Chicago"
    And a user "chicago_guy" exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1", points: "0"
    And sphinx is indexed
    And I am logged in as "chicago_guy"
    And I go to the shouts page

    When I follow "Add More"
    And I fill in "search_places_autocomplete" with "Paramount Room"
    And I wait for "3" seconds
    And I select the option containing "Paramount Room" in the autocomplete list
    And I fill in "text" with "Love their burger"
    And I follow "Add"
    Then I should see "We added your shout for Paramount Room"

