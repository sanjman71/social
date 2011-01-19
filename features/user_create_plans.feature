Feature: Add plans
  As a user I want to add planned checkins

  @javascript
  Scenario: User adds a planned checkin by looking up a place
    Given a city: "Chicago" should exist with name: "Chicago"
    And a user exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1", points: "0"
    And user "chicago_guy" has email "chicago_guy@outlately.com"
    And sphinx is indexed
    And I am logged in as "chicago_guy"
    And I go to the plans page

    When I follow "Add More"
    And I fill in "search_places_autocomplete" with "Paramount Room"
    And I wait for "3" seconds
    And I select the option containing "Paramount Room" in the autocomplete list
    And I follow "Add"

    Then I should be on the plans page
    And I should see "We added Paramount Room to your todo list"
