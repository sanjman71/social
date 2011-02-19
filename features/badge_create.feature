Feature: Create badges
  As a admin, I want to create new badges with tags

  @javascript
  Scenario:
    Given a city: "Chicago" should exist with name: "Chicago"
    And a state: "IL" should exist with code: "IL"
    And a user exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1", points: "0"
    And user "chicago_guy" is an admin
    And a location "Chicago Starbucks" exists with name: "Chicago Starbucks", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And location "Chicago Starbucks" is tagged with "coffee, snickers"
    And user "chicago_guy" checked in to "Chicago Starbucks" "5 minutes ago"
    And I am logged in as "chicago_guy"
    And I go to path "/admin/badges"

    # create badge
    Then I should see "Add Badge"
    And I follow "Add Badge"
    And I fill in "Name" with "Candy Crazy"
    And I fill in "Tagline" with "Candy-licious"
    And I press "Create"

    Then I should see "Created badge 'Candy Crazy'"

    # add badge tags
    And I follow "+"
    And I fill in "search_tags_autocomplete" with "snickers"
    And I wait for "1" seconds
    And I select the option containing "snickers" in the autocomplete list
    And I follow "Apply"
    And the delayed jobs are processed
    And the resque jobs are processed

    # reload the page
    And I go to path "/admin/badges"
    Then I should see "Candy Crazy (1)" within "div#badge"
    And I should see "snickers" within "div#badge"