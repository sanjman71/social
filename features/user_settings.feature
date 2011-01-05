Feature: User Location
  A user must choose a default location
  
  @no-txn
  Scenario: User without a location is asked to choose a default one
    Given a user "chicago_guy" who is a "straight" "male"
    And I am logged in as "chicago_guy"
    Given sphinx is indexed
    When I go to the home page
    Then I should see "Please choose a location"
    And I should see "Handle"
    And I should see "Email Address"
    And I should see "Location"

