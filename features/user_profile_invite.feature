Feature: User Profile Invite
  As a user
  I want to send invites or invite pokes to other users from their profile page
  
  @javascript @profile @invite
  Scenario: A user sends an invite poke from a non-member profile
    Given a city: "Chicago" should exist with name: "Chicago"
    And a user "chicago_guy" exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And a user "chicago_gal" exists with handle: "chicago_gal", gender: "Female", orientation: "Straight", city: city "Chicago", member: "0"
    And a user "chicago_friend" exists with handle: "chicago_friend", gender: "Female", orientation: "Straight", city: city "Chicago", member: "1"
    And "chicago_friend" is friends with "chicago_gal"
    And I am logged in as "chicago_guy"
    And user "chicago_friend" has email "chicago_friend@outlately.com"
    When I go to chicago_gal's profile page
    Then I should see "Want Her To Join" within "#profile-nav"

    # When I click "a#profile-invite"
    When I follow "Want Her To Join"
    Then "chicago_friend@outlately.com" should receive an email with subject "Outlately: Can you invite your friend chicago_gal to sign up..."
