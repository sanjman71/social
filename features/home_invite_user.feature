Feature: Invite users by poking their friends
  In order to build virality around the site,
  As a user
  I want to ask members to invite their friends that I think are interesting

  @javascript
  Scenario: See a user in the stream and ask another member to invite them
    Given a city: "Chicago" should exist with name: "Chicago"
    And a state: "IL" should exist with code: "IL"
    # create users
    And a user "chicago_guy1" exists with handle: "chicago_guy1", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And user "chicago_guy1" has email "chicago_guy1@outlately.com"
    And a user "chicago_guy2" exists with handle: "chicago_guy2", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And a user "chicago_friend1" exists with handle: "chicago_friend1", gender: "Male", orientation: "Straight", city: city "Chicago", member: "0"
    And a user exists with handle: "chicago_friend2", gender: "Male", orientation: "Straight", city: city "Chicago", member: "0"
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
    And I am logged in as "chicago_guy2"
    And sphinx is indexed

    When I go to the home page
    Then I should see "Everyone" within "ul#social-stream-nav li.active"
    And I should see "chicago_guy1" within "ul#social-stream"
    And I should see "chicago_friend1" within "ul#social-stream"

    When I follow "Invite Him"
    And the delayed jobs are processed
    Then "chicago_guy1@outlately.com" should receive an email with subject "Outlately: Somebody wants your friend chicago_friend1 to sign up..."
    And I open the email with subject "Outlately: Somebody wants your friend chicago_friend1 to sign up..."
    Then I should see "chicago_guy2 wants chicago_friend1 to join Outlately.  Since you're friends with chicago_friend1," in the email body
    And I follow "invite" in the email
    Then I should be on the invite page
