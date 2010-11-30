Feature: User Profile
  I want to see user profiles

  @javascript
  Scenario: Visiting a user profile costs 10 bucks
    Given a user "chicago_guy" in "Chicago, IL" who is a "straight" "male"
    And a user "chicago_coffee_gal" in "Chicago, IL" who is a "straight" "female"
    And a user "chicago_guy" with "100" dollars
    And I am logged in as "chicago_guy"
    Given sphinx is indexed
    When I go to chicago_coffee_gal's profile page
    Then I should see "90" within "span#user_points"

  @javascript
  Scenario: User is alerted when they visit a user profile and are out of bucks
    Given a user "chicago_guy" in "Chicago, IL" who is a "straight" "male"
    And a user "chicago_coffee_gal" in "Chicago, IL" who is a "straight" "female"
    And a user "chicago_guy" with "10" dollars
    And sphinx is indexed
    And I am logged in as "chicago_guy"
    When I go to chicago_coffee_gal's profile page
    Then I should see "0" within "span#user_points"
    And I should see "You are out of bucks"