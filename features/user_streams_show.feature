Feature: User Streams
  As a user I want to see streams of user checkin activity

  @javascript
  Scenario: User should see all member checkins in the default Outlately stream
    Given a city: "Chicago" should exist with name: "Chicago"
    And a state: "IL" should exist with code: "IL"
    And a user exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And a user exists with handle: "chicago_coffee_gal", gender: "Female", orientation: "Straight", city: city "Chicago", member: "1"
    And a user exists with handle: "chicago_coffee_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And a location exists with name: "Chicago Starbucks", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And a location exists with name: "Chicago Lavazza", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And user "chicago_coffee_gal" checked in to "Chicago Starbucks"
    And user "chicago_coffee_guy" checked in to "Chicago Lavazza"
    And I am logged in as "chicago_guy"
    When sphinx is indexed
    When I go to the home page
    Then I should see "Outlately" within "span.current.stream_name"
    And I should see "chicago_coffee_gal" within "div.stream#outlately"
    And I should see "chicago_coffee_guy" within "div.stream#outlately"

  @javascript
  Scenario: Male user should see member checkins by females in the Ladies stream
    Given a city: "Chicago" should exist with name: "Chicago"
    And a state: "IL" should exist with code: "IL"
    And a user exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And a user exists with handle: "chicago_coffee_gal", gender: "Female", orientation: "Straight", city: city "Chicago", member: "1"
    And a user exists with handle: "chicago_coffee_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And a location exists with name: "Chicago Starbucks", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And a location exists with name: "Chicago Lavazza", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And user "chicago_coffee_gal" checked in to "Chicago Starbucks"
    And user "chicago_coffee_guy" checked in to "Chicago Lavazza"
    And I am logged in as "chicago_guy"
    When sphinx is indexed
    When I go to the home page
    And I follow "Ladies" within "span#stream_list"
    Then I should see "Ladies" within "span.current.stream_name"
    And I should see "chicago_coffee_gal" within "div.stream#ladies"
    And I should not see "chicago_coffee_guy" within "div.stream#ladies"

  @javascript
  Scenario: User should see user checkins by friends in the Friends stream
    Given a city: "Chicago" should exist with name: "Chicago"
    And a state: "IL" should exist with code: "IL"
    # create users
    And a user exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And a user exists with handle: "chicago_friend1", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And a user exists with handle: "chicago_friend2", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And a user exists with handle: "chicago_guy2", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    # create locations
    And a location exists with name: "Chicago Starbucks", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And a location exists with name: "Chicago Lavazza", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And a location exists with name: "Chicago Argo Tea", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    # add checkins
    And user "chicago_friend1" checked in to "Chicago Starbucks"
    And user "chicago_friend2" checked in to "Chicago Lavazza"
    And user "chicago_guy2" checked in to "Chicago Argo Tea"
    # add friends
    And "chicago_friend1" is friends with "chicago_guy"
    And "chicago_friend2" is friends with "chicago_guy"
    And I am logged in as "chicago_guy"
    When sphinx is indexed
    When I go to the home page
    And I follow "Friends" within "span#stream_list"
    Then I should see "Friends" within "span.current.stream_name"
    And I should see "chicago_friend1" within "div.stream#friends"
    And I should see "chicago_friend2" within "div.stream#friends"
    And I should not see "chicago_guy2" within "div.stream#friends"

  # @javascript
  # Scenario: User sees checkins in the past day in the Today stream
  #   Given a user "chicago_guy" in "Chicago, IL" who is a "straight" "male"
  #   And a user "chicago_coffee_gal" in "Chicago, IL" who is a "straight" "female"
  #   And a user "chicago_coffee_guy" in "Chicago, IL" who is a "straight" "male"
  #   And "chicago_coffee_gal" checked in to "Chicago Starbucks" in "Chicago" about "10 hours ago"
  #   And "chicago_coffee_guy" checked in to "Chicago Lavazza" in "Chicago" about "3 days ago"
  #   And I am logged in as "chicago_guy"
  #   When sphinx is indexed
  #   When I go to the home page
  #   And I follow "Today"
  #   Then I should see "Today" within "span.current.stream_name"
  #   And I should see "chicago_coffee_gal" within "div.stream#today"
  #   And I should not see "chicago_coffee_guy" within "div.stream#today"

  # @javascript
  # Scenario: User sees trending checkins in the Trending stream
  #   Given a user "chicago_guy" in "Chicago, IL" who is a "straight" "male"
  #   And a user "chicago_user1" in "Chicago, IL" who is a "straight" "female"
  #   And a user "chicago_user2" in "Chicago, IL" who is a "straight" "female"
  #   And a user "chicago_user3" in "Chicago, IL" who is a "straight" "female"
  #   And a user "chicago_user4" in "Chicago, IL" who is a "straight" "female"
  #   And "chicago_user1" checked in to "Chicago Starbucks" in "Chicago" about "1 hour ago"
  #   And "chicago_user2" checked in to "Chicago Peets" in "Chicago" about "25 hours ago"
  #   And "chicago_user3" checked in to "Chicago Lavazza" in "Chicago" about "49 hours ago"
  #   And "chicago_user4" checked in to "Chicago Espresso" in "Chicago" about "73 hours ago"
  #   And I am logged in as "chicago_guy"
  #   When sphinx is indexed
  #   When I go to the home page
  #   And I follow "Trending"
  #   Then I should see "Trending" within "span.current.stream_name"
  #   And I should see "Chicago Starbucks" within "div.stream#trending"
  #   And I should see "Chicago Peets" within "div.stream#trending"
  #   And I should see "Chicago Lavazza" within "div.stream#trending"

  @javascript
  Scenario: User without a location is redirected to user edit page and prompted to enter a location
    Given a user "chicago_guy" who is a "straight" "male"
    And I am logged in as "chicago_guy"
    When sphinx is indexed
    When I go to the home page
    Then I should be on chicago_guy's user edit page
    And I should see "My Profile" within "div.mat"
