Feature: Add Bucks
  As a user I want to add bucks to my account

  @javascript
  Scenario: User clicks Get more bucks to add points to their account
    Given a user "chicago_guy" in "Chicago, IL" who is a "straight" "male"
    And a user "chicago_guy" with "0" dollars
    And sphinx is indexed
    And I am logged in as "chicago_guy"
    When I go to the home page
    And I press "Get more bucks"
    Then I should see "100" within "span#user_points"
    
