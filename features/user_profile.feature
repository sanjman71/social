Feature: User Profile
  I want to see user profiles

  @no-txn
  Scenario: Visiting a user profile costs money
    Given a user "chicago_guy" in "Chicago, IL" who is a "straight" "male"
    And a user "chicago_coffee_gal" in "Chicago, IL" who is a "straight" "female"
    And a user "chicago_guy" with "100" dollars
    And I am logged in as "chicago_guy"
    When I go to chicago_coffee_gal's profile page
    When sphinx is indexed
    Then I should see "90" within "span#user_points"
