Feature: User Profile
  As a user
  I want to see other user profiles

  Background:
    Given a city: "Chicago" should exist with name: "Chicago"
    And a user "chicago_guy" exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1", points: "100"
    And a user "chicago_gal" exists with handle: "chicago_gal", gender: "Female", orientation: "Straight", city: city "Chicago", member: "1", points: "100"

  @profile
  Scenario: A user should see 'default' social dna if the they don't have any other badges
    Given I am logged in as "chicago_guy"
    When I go to chicago_guy's profile page
    Then I should see "My Social DNA"
    And I should see "Create your Social DNA" within "ul#profile-social-dna"

  @profile
  Scenario: A user visiting another user's profile costs 10 points
    Given I am logged in as "chicago_guy"
    When I go to chicago_gal's profile page
    Then I should see "90" within "div#my-points div#screen"

  @profile
  Scenario: A user visiting a member's profile should see a 'Message' button
    Given I am logged in as "chicago_guy"
    When I go to chicago_gal's profile page
    Then I should see "Message"

  @profile
  Scenario: A user visiting a non-member's profile should see an 'Ask Her To Join' button
    Given a user "chicago_nonmember" exists with handle: "chicago_nonmember", gender: "Female", orientation: "Straight", city: city "Chicago", member: "0", points: "0"
    And I am logged in as "chicago_guy"
    When I go to chicago_nonmember's profile page
    Then I should see "Ask Her To Join"

  @profile @tracker
  Scenario: Visiting a user profile via email click should track via and by
    Given a user "chicago_guy" exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", member: "1"
    And I am logged in as "chicago_guy"
    And I go to path "/users/1/via/email"
    Then I should be on chicago_guy's profile page
    And I should see "_gaq.push(['_trackPageview', '/users/1/via/email'])"
    And I should see "_gaq.push(['_trackPageview', '/users/1/by/1'])"

