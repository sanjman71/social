Feature: User suggestions
  As as user, I want to see and act on my suggestions
  
  Background:
    Given a city: "Chicago" should exist with name: "Chicago"
    And a state: "IL" should exist with code: "IL"
    And a user exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And user "chicago_guy" has email "chicago_guy@outlately.com"
    Then a user "chicago_guy" should exist with handle: "chicago_guy"
    And a user exists with handle: "chicago_gal", gender: "Female", orientation: "Straight", city: city "Chicago", member: "1"
    And user "chicago_gal" has email "chicago_gal@outlately.com"
    Then a user "chicago_gal" should exist with handle: "chicago_gal"
    And a location exists with name: "Chicago Starbucks", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    Then a location "Chicago Starbucks" should exist with name: "Chicago Starbucks"
    And a location exists with name: "Chicago Lavazza", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    Then a location "Chicago Lavazza" should exist with name: "Chicago Lavazza"
    And a suggestion exists for users "chicago_guy" and "chicago_gal" at location "Chicago Starbucks"

  @javascript
  Scenario: User should be able to schedule a date, and then re-locate
    Given I am logged in as "chicago_guy"
    When I go to the suggestions page
    Then I should see "meet chicago_gal"
    And I follow "Details"
    And I follow "Pick a Date"
    And I fill in "Date" with tomorrow
    And I fill in "Message" with "Fun, fun"
    And I press "Schedule"
    And the delayed jobs are processed

    Then I should see "Your suggestion was scheduled!"
    And "chicago_gal@outlately.com" should receive an email with subject "Outlately: chicago_guy suggested meeting tomorrow"

    When I follow "Details"
    And I follow "Change Location"
    When I fill in "search_places_autocomplete" with "Paramount Room"
    And I wait for "3" seconds
    And I select the option containing "Paramount Room" in the autocomplete list
    And I follow "That's the place"

    Then I should see "Your suggestion was re-located!"
    And "chicago_gal@outlately.com" should receive an email with subject "Outlately: chicago_guy suggested meeting at Paramount Room"

    @javascript
    Scenario: User should receive an email when a suggestion is scheduled, and then re-schedule
      Given I am logged in as "chicago_gal"
      And "chicago_guy" schedules his suggestion with "chicago_gal" "1.day.from_now"
      Then "chicago_gal@outlately.com" should receive an email with subject "Outlately: chicago_guy suggested meeting tomorrow"
      When I open the email
      And I follow "confirm" in the email
      Then I should see "chicago_guy" within "div#suggestion"
      And I follow "Details"
      And I follow "Re-schedule"
      And I fill in "Date" with tomorrow
      And I fill in "Message" with "Fun, fun"
      And I press "Re-schedule"
      And the delayed jobs are processed

      Then I should see "Your suggestion was re-scheduled!"
      And "chicago_guy@outlately.com" should receive an email with subject "Outlately: chicago_gal re-scheduled and suggested meeting tomorrow"

    @javascript
    Scenario: User should receive an email when a suggestion is scheduled, and then confirm
      Given I am logged in as "chicago_gal"
      And "chicago_guy" schedules his suggestion with "chicago_gal" "1.day.from_now"
      Then "chicago_gal@outlately.com" should receive an email with subject "Outlately: chicago_guy suggested meeting tomorrow"
      When I open the email
      And I follow "confirm" in the email
      Then I should see "chicago_guy" within "div#suggestion"
      And I follow "Details"
      And I follow "Confirm"
      And the delayed jobs are processed

      Then I should see "Your suggestion was confirmed!"
      And "chicago_guy@outlately.com" should receive an email with subject "Outlately: chicago_gal confirmed"
      When I open the email
      Then I should see "Click" in the email body
      And I follow "here" in the email
      Then I should see "chicago_guy" within "div#suggestion"
    