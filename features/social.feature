Feature: New home page
  As a user
  I want to see friends out and friends I'm following

  Background:
    Given a city: "Chicago" should exist with name: "Chicago"
    And a state: "IL" should exist with code: "IL"

  @javascript
  Scenario: User sees friends out
    # create users
    Given a user "Chicago M." exists with handle: "Chicago M.", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And a user "Chicago A." exists with handle: "Chicago A.", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And user "Chicago A." has email "chicago.a@gmail.com"
    And a user "Chicago B." exists with handle: "Chicago B.", gender: "Male", orientation: "Straight", city: city "Chicago", member: "0"
    # create locations
    And a location exists with name: "Chicago Starbucks", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And a location exists with name: "Chicago Lavazza", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And a location exists with name: "Chicago Argo Tea", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    # add checkins
    And user "Chicago A." checked in to "Chicago Starbucks" "5 minutes ago"
    
    # add friends
    And "Chicago M." is friends with "Chicago A."
    And "Chicago M." is friends with "Chicago B."
    And the resque jobs are processed
    And I am logged in as "Chicago M."
    
    When I go to the home page
    Then I should see "Chicago A."
    
    When I follow "Message"
    And I fill in "message_body" with "Hey there"
    And I press "Send"
    And I wait for "2" seconds

    And the resque jobs are processed
    And "chicago.a@gmail.com" should receive an email with subject "Outlately: Chicago M. sent you a message..."
    And I open the email
    Then I should see "Hey there" in the email body
    