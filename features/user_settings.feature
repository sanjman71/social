Feature: User Location
  A user must choose a default location
  
  @javascript @settings
  Scenario: User without a location is asked to choose a default one
    Given a user exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", member: "1"
    And I am logged in as "chicago_guy"
    Given sphinx is indexed
    When I go to the home page
    Then I should be on the settings page
    And I should see "Please choose a location"
    And I should see "Email Address"
    And I should see "Location"
    # add location
    And I press "Update"
    Then I should be on the home page
