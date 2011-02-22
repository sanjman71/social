Feature: Home Streams
  As a user
  I want to see checkin streams on the home page and be able to interact with them

  Background:
    Given a city: "Chicago" should exist with name: "Chicago"
    And a state: "IL" should exist with code: "IL"

  Scenario: User should see all member and non-member checkins in the default Everyone stream
    Given a user exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And a user exists with handle: "chicago_coffee_gal", gender: "Female", orientation: "Straight", city: city "Chicago", member: "1"
    And a user exists with handle: "chicago_coffee_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And a location exists with name: "Chicago Starbucks", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And a location exists with name: "Chicago Lavazza", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And user "chicago_coffee_gal" checked in to "Chicago Starbucks" "15 minutes ago"
    And user "chicago_coffee_guy" checked in to "Chicago Lavazza" "5 minutes ago"
    And I am logged in as "chicago_guy"
    And sphinx is indexed
    When I go to the home page
    And I wait for "2" seconds
    Then I should see "Everyone" within "ul#social-stream-nav li.active"
    And I should see "chicago_coffee_gal" within "ul#social-stream"
    And I should see "chicago_coffee_guy" within "ul#social-stream"

  Scenario: User should see not see disabled user's checkins in the default Everyone stream
    Given a user exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And a user exists with handle: "chicago_coffee_gal", gender: "Female", orientation: "Straight", city: city "Chicago", member: "1"
    And a user exists with handle: "chicago_coffee_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1", state: "disabled"
    And a location exists with name: "Chicago Starbucks", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And a location exists with name: "Chicago Lavazza", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And user "chicago_coffee_gal" checked in to "Chicago Starbucks" "15 minutes ago"
    And user "chicago_coffee_guy" checked in to "Chicago Lavazza" "5 minutes ago"
    And I am logged in as "chicago_guy"
    And sphinx is indexed
    When I go to the home page
    And I wait for "2" seconds
    Then I should see "Everyone" within "ul#social-stream-nav li.active"
    And I should see "chicago_coffee_gal" within "ul#social-stream"
    And I should not see "chicago_coffee_guy" within "ul#social-stream"

  Scenario: Male user should see female member checkins in the Ladies stream
    Given a user exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And a user exists with handle: "chicago_coffee_gal", gender: "Female", orientation: "Straight", city: city "Chicago", member: "1"
    And a user exists with handle: "chicago_coffee_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And a location exists with name: "Chicago Starbucks", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And a location exists with name: "Chicago Lavazza", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And user "chicago_coffee_gal" checked in to "Chicago Starbucks" "15 minutes ago"
    And user "chicago_coffee_guy" checked in to "Chicago Lavazza" "5 minutes ago"
    And I am logged in as "chicago_guy"
    And sphinx is indexed
    When I go to the home page
    And I follow "Ladies" within "ul#social-stream-nav"
    And I wait for "2" seconds
    Then I should see "Ladies" within "ul#social-stream-nav li.active"
    And I should see "chicago_coffee_gal" within "ul#social-stream"
    And I should not see "chicago_coffee_guy" within "ul#social-stream"

  Scenario: User should see friend checkins in the Friends stream
    # create users
    Given a user exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And a user exists with handle: "chicago_friend1", gender: "Male", orientation: "Straight", city: city "Chicago", member: "0"
    And a user exists with handle: "chicago_friend2", gender: "Male", orientation: "Straight", city: city "Chicago", member: "0"
    And a user exists with handle: "chicago_guy2", gender: "Male", orientation: "Straight", city: city "Chicago", member: "0"
    # create locations
    And a location exists with name: "Chicago Starbucks", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And a location exists with name: "Chicago Lavazza", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And a location exists with name: "Chicago Argo Tea", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    # add checkins
    And user "chicago_friend1" checked in to "Chicago Starbucks" "5 minutes ago"
    And user "chicago_friend2" checked in to "Chicago Lavazza" "15 minutes ago"
    And user "chicago_guy2" checked in to "Chicago Argo Tea" "3 minutes ago"
    # add friends
    And "chicago_friend1" is friends with "chicago_guy"
    And "chicago_friend2" is friends with "chicago_guy"
    And sphinx is indexed
    And the resque jobs are processed
    And I am logged in as "chicago_guy"

    When I go to the home page
    And I follow "Friends" within "ul#social-stream-nav"
    And I wait for "2" seconds
    Then I should see "Friends" within "ul#social-stream-nav li.active"
    And I should see "chicago_friend1" within "ul#social-stream"
    And I should see "chicago_friend2" within "ul#social-stream"
    And I should not see "chicago_guy2" within "ul#social-stream"

  @javascript @checkins
  Scenario: User should be able to see checkin details and do stuff
    Given a user exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And a user exists with handle: "chicago_coffee_gal", gender: "Female", orientation: "Straight", city: city "Chicago", member: "1"
    And user "chicago_coffee_gal" has email "chicago_coffee_gal@gmail.com"
    And a location exists with name: "Chicago Starbucks", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And a location exists with name: "Chicago Lavazza", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And user "chicago_coffee_gal" checked in to "Chicago Starbucks" "15 minutes ago"
    And I am logged in as "chicago_guy"
    And sphinx is indexed

    When I go to the home page
    Then I should see "Everyone" within "ul#social-stream-nav li.active"
    And I should see "chicago_coffee_gal" within "ul#social-stream"

    When I click "li.checkin div.closed"
    And I wait for "2" seconds
    Then I should see "Ask Her To Plan a Checkin"
    And I should see "Plan To Go Here"

    # send add_todo_request
    When I follow "Ask Her To Plan a Checkin"
    And I wait for "2" seconds
    Then I should see "We'll send them a note"

    When the resque jobs are processed
    Then "chicago_coffee_gal@gmail.com" should receive an email with subject "Outlately: chicago_guy sent you a message..."
    When I open the email with subject "Outlately: chicago_guy sent you a message..."
    Then I should see "He wants you to plan a checkin or two.  Its a great way to meet new people." in the email body

    # plan a checkin
    When I follow "Plan To Go Here"
    And I choose "today" within "div#social-stream-details"
    And I press "add_todo" within "div#social-stream-details"
    Then I should see "If you go there within 7 days"

  @javascript @todos
  Scenario: User should be able to see todo details and do stuff
    Given a user "chicago_guy" exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And a user "chicago_coffee_gal" exists with handle: "chicago_coffee_gal", gender: "Female", orientation: "Straight", city: city "Chicago", member: "1"
    And user "chicago_coffee_gal" has email "chicago_coffee_gal@gmail.com"
    And a location "Chicago Starbucks" exists with name: "Chicago Starbucks", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And a planned_checkin exists with user: user "chicago_coffee_gal", location: location "Chicago Starbucks", planned_at: "#{1.day.ago}", going_at: "#{1.day.from_now}"
    And I am logged in as "chicago_guy"
    And sphinx is indexed
    When I go to the home page
    Then I should see "Everyone" within "ul#social-stream-nav li.active"
    And I should see "chicago_coffee_gal" within "ul#social-stream"

    When I click "li.todo div.closed"
    And I wait for "2" seconds
    Then I should see "Share a Drink"

    When I follow "Share a Drink"
    And I wait for "2" seconds
    Then I should see "We'll send them a message saying you'd like to grab a drink"

    When the resque jobs are processed
    Then "chicago_coffee_gal@gmail.com" should receive an email with subject "Outlately: from chicago_guy, re: your planned checkin at Chicago Starbucks..."
    When I open the email with subject "Outlately: from chicago_guy, re: your planned checkin at Chicago Starbucks..."
    Then I should see "chicago_guy wants to share a drink..." in the email body
    Then I should see "So what do you think? Want to have a drink with him?" in the email body

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
  Scenario: User without a location is redirected to their settings page and prompted to enter a location
    Given a user "chicago_guy" exists with handle: "chicago_guy", gender: "Male"
    And I am logged in as "chicago_guy"
    When sphinx is indexed
    When I go to the home page
    Then I should be on path "/settings"
    And I should see "My Settings"
