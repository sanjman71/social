Feature: Invite users by poking their friends
  In order to build virality around the site,
  As a user
  I want to ask members to invite their friends that I think are interesting

  Background:
    Given a city: "Chicago" should exist with name: "Chicago"
    And a state: "IL" should exist with code: "IL"
    # create users
    And a user "chicago_guy1" exists with handle: "chicago_guy1", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And user "chicago_guy1" has email "chicago_guy1@gmail.com"
    And a user "chicago_guy2" exists with handle: "chicago_guy2", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And user "chicago_guy2" has email "chicago_guy2@gmail.com"
    And a user "chicago_friend1" exists with handle: "chicago_friend1", gender: "Male", orientation: "Straight", city: city "Chicago", member: "0"
    And user "chicago_friend1" has email "chicago_friend1@gmail.com"
    And a user exists with handle: "chicago_friend2", gender: "Male", orientation: "Straight", city: city "Chicago", member: "0"
    And user "chicago_friend2" has email "chicago_friend2@gmail.com"
    # create locations
    And a location "Chicago Starbucks" exists with name: "Chicago Starbucks", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And a location "Chicago Lavazza" exists with name: "Chicago Lavazza", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And a location "Chicago Argo Tea" exists with name: "Chicago Argo Tea", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    # add checkins
    And user "chicago_guy1" checked in to "Chicago Argo Tea"
    And user "chicago_guy2" checked in to "Chicago Argo Tea"
    And user "chicago_friend1" checked in to "Chicago Starbucks"
    # add friends
    And "chicago_friend1" is friends with "chicago_guy1"
    And the resque jobs are reset
    
  @javascript @invite @email
  Scenario: Clicking 'Ask Him To Join' in a user stream sends a poke message to their friend
    Given I am logged in as "chicago_guy2"
    And sphinx is indexed
    When I go to the home page
    Then I should see "Everyone" within "ul#social-stream-nav li.active"
    And I should see "chicago_guy1" within "ul#social-stream"
    And I should see "chicago_friend1" within "ul#social-stream"

    When I follow "Ask Him To Join"
    # wait for ajax call
    And I wait for "2" seconds
    And the resque jobs are processed
    Then "chicago_guy1@gmail.com" should receive an email with subject "Outlately: Can you invite your friend chicago_friend1 to sign up..."
    And I open the email with subject "Outlately: Can you invite your friend chicago_friend1 to sign up..."
    Then I should see "chicago_guy2 wants chicago_friend1 to join Outlately.  Since you're friends with chicago_friend1," in the email body
    And I follow "invite" in the email
    Then I should be on the invite page

  @javascript @invite @email
  Scenario: Clicking 'Ask Him To Join' on an already poked user should not send another message
    Given I am logged in as "chicago_guy2"
    # chicago_guy2 already poked chicago_friend1
    And user "chicago_guy2" poked "chicago_guy1" to invite "chicago_friend1"
    # clicking invite shouldn't send another email
    When 3 days have passed
    And a clear email queue
    And the resque jobs are reset
    And sphinx is indexed
    And I go to the home page
    # wait for streams
    And I wait for "2" seconds
    Then I should see "Ask Him To Join"

    When I follow "Ask Him To Join"
    # wait for ajax call
    And I wait for "2" seconds
    And the resque jobs are processed
    Then "chicago_guy1@gmail.com" should receive no emails
