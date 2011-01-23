Feature: User Profile
  As a user
  I want to see other user profiles

  Background:
    Given a city: "Chicago" should exist with name: "Chicago"
    And a user exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1", points: "100"
    And a user exists with handle: "chicago_gal", gender: "Female", orientation: "Straight", city: city "Chicago", member: "1", points: "100"

  @javascript
  Scenario: A user should see 'default' social dna if they don't have any other badges
    Given I am logged in as "chicago_guy"
    When I go to chicago_guy's profile page
    Then I should see "My Social DNA"
    And I should see "Create your Social DNA" within "ul#profile-social-dna"

  @javascript
  Scenario: A user visiting a another user's profile costs 10 points
    Given I am logged in as "chicago_guy"
    When I go to chicago_gal's profile page
    Then I should see "90" within "div#my-points div#screen"
    