Feature: Add plans
  As a user I want to add planned checkins

  @javascript
  Scenario: User adds a planned checkin from the plans page
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
    And I fill in "going" with tomorrow
    And I follow "Add"

    Then I should be on the plans page
    And I should see "We added Paramount Room to your todo list"

  @javascript
  Scenario: User adds a planned checkins from the home page with the 'Plan To Go Here' button
    Given a city: "Chicago" should exist with name: "Chicago"
    And a state: "IL" should exist with code: "IL"
    And a user "chicago_guy" exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And user "chicago_guy" has email "chicago_guy@outlately.com"
    And a user "chicago_gal" exists with handle: "chicago_gal", gender: "Female", orientation: "Straight", city: city "Chicago", member: "1"
    And user "chicago_gal" has email "chicago_gal@outlately.com"
    And a location "Chicago Starbucks" exists with name: "Chicago Starbucks", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And user "chicago_gal" checked in to "Chicago Starbucks" "5 minutes ago"
    And I am logged in as "chicago_guy"
    And sphinx is indexed
    When I go to the home page
    Then I should see "Everyone" within "ul#social-stream-nav li.active"
    And I should see "chicago_gal" within "ul#social-stream"

    And I follow "Plan To Go Here"
    And I choose "today" within "li.checkin"
    And I press "add_todo" within "li.checkin"
    Then I should see "If you go there within 7 days"
