Feature: User Profile
  I want to see user profiles and be able to interact with them

  Background:
    Given a city: "Chicago" should exist with name: "Chicago"
    And a user exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1", points: "100"
    And a user exists with handle: "chicago_gal", gender: "Female", orientation: "Straight", city: city "Chicago", member: "1", points: "100"

  @javascript
  Scenario: Visiting a user profile costs 10 points
    Given I am logged in as "chicago_guy"
    When I go to chicago_gal's profile page
    Then I should see "90" within "div#my-points div#screen"

  @javascript
  Scenario: Visit a user profile and send a message
    Given I am logged in as "chicago_guy"
    And user "chicago_gal" has email "chicago_gal@outlately.com"
    When I go to chicago_gal's profile page
    Then I should see "Message"

    And I follow "Message"
    And I fill in "message_body" with "Hey there"
    And I press "Send"
    And I wait for "3" seconds
    Then I should see "Sent message!"

    And the delayed jobs are processed
    Then "chicago_gal@outlately.com" should receive an email with subject "chicago_guy sent you a message"
    And I open the email
    Then I should see "Hey there" in the email body
    And I follow "here" in the email
    Then I should be on chicago_guy's profile page
    