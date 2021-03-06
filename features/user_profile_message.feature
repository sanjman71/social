Feature: User Profile Message
  As a user
  I want to send messages to other users from their profile page

  @javascript @profile @message
  Scenario: A user sends a message to another member from their profile
    Given a city: "Chicago" should exist with name: "Chicago"
    And a user "chicago_guy" exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And a user "chicago_gal" exists with handle: "chicago_gal", gender: "Female", orientation: "Straight", city: city "Chicago", member: "1"
    And I am logged in as "chicago_guy"
    And the resque jobs are reset
    And user "chicago_gal" has email "chicago_gal@outlately.com"
    And I go to chicago_gal's profile page
    
    When I click "div.actions"
    And I follow "Send Message"
    And I fill in "message_body" with "Hey there"
    And I press "Send"
    And I wait for "3" seconds
    Then I should see "Sent message"

    And the resque jobs are processed
    And "chicago_gal@outlately.com" should receive an email with subject "Outlate.ly: chicago_guy sent you a message..."
    And I open the email
    Then I should see "Hey there" in the email body
    And I should see "utm_campaign" in the email body
    And I follow "here" in the email
    Then I should be on chicago_guy's message compose page

  