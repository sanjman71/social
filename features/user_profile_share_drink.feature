Feature: User Profile Share a Drink
  As a user
  I want to send a message that I would like to share a drink with another user
  
  @profile
  Scenario: A user sends a 'Share a Drink' message to another user
    Given a city: "Chicago" should exist with name: "Chicago"
    And a user "chicago_guy" exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And user "chicago_guy" has email "chicago_guy@gmail.com"
    And a user "chicago_gal" exists with handle: "chicago_gal", gender: "Female", orientation: "Straight", city: city "Chicago", member: "1"
    And user "chicago_gal" has email "chicago_gal@gmail.com"
    And I am logged in as "chicago_guy"

    And I go to chicago_gal's share a drink page
    Then I should be on chicago_gal's profile page
    And I should see "_gaq.push(['_trackPageview', '/action/share/drink'])"
    # And I should see "We'll send them a note saying you'd like to grab a drink"

    And the resque jobs are processed
    Then "chicago_gal@gmail.com" should receive an email with subject "Outlately: Want to share a drink with..."
    When I open the email with subject "Outlately: Want to share a drink with..."
    Then I should see "chicago_guy wants to share a drink with you" in the email body
    Then I should see "Click" in the email body
  