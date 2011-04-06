Feature: User Profile
  As a user
  I want to see other user profiles

  Background:
    Given a city: "Chicago" should exist with name: "Chicago"
    And a user "chicago_guy" exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1", points: "100"
    And a user "chicago_gal" exists with handle: "chicago_gal", gender: "Female", orientation: "Straight", city: city "Chicago", member: "1"

  # @profile
  # Scenario: A user should see 'default' social dna if the they don't have any other badges
  #   Given I am logged in as "chicago_guy"
  #   When I go to chicago_guy's profile page
  #   Then I should see "My Social DNA"
  #   And I should see "Create your Social DNA" within "ul#profile-social-dna"

  # @profile
  # Scenario: A user visiting another user's profile costs 10 points
  #   Given I am logged in as "chicago_guy"
  #   When I go to chicago_gal's profile page
  #   Then I should see "90" within "div#my-points div#screen"

  @profile
  Scenario: A user visiting a member's profile should see 'Send Message' in the actions menu
    Given I am logged in as "chicago_guy"

    When I go to chicago_gal's profile page
    And I click "div.actions"
    Then I should see "Send Message"

  @profile
  Scenario: A user visiting a member's profile should see be able to follow them
    Given I am logged in as "chicago_guy"

    When I go to chicago_gal's profile page
    And I click "div.actions"
    Then I should see "Follow"

    When I follow "Follow"
    And I wait for "2" seconds
    Then I should see "You are now following chicago_gal"

    # the menu should now have 'Unfollow'
    When I click "div.actions"
    Then I should see "Unfollow"

  @profile
  Scenario: A user visiting a non-member's profile should see 'Invite Her' in the actions menu
    Given a user "chicago_nonmember" exists with handle: "chicago_nonmember", gender: "Female", orientation: "Straight", city: city "Chicago", member: "0"
    And I am logged in as "chicago_guy"

    When I go to chicago_nonmember's profile page
    And I click "div.actions"
    Then I should see "Invite her"

