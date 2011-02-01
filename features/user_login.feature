Feature: User Login
  As a user
  I want to login with my facebook account

  Background:
    Given a city: "Chicago" should exist with name: "Chicago"

  @login
  Scenario: Active users should be allowed to login
    Given a user "facebook_guy" exists with handle: "facebook_guy", city: city "Chicago", gender: "Male", orientation: "Straight", member: "1", facebook_id: "99999", sign_in_count: 1
    Given I login with facebook as "facebook_guy"
    Then I should be on the home page
    And I should see "_gaq.push(['_trackPageview', '/login/completed'])"

  @login
  Scenario: Disabled users should not be allowed to login
    Given a user "facebook_guy" exists with handle: "facebook_guy", gender: "Male", orientation: "Straight", member: "1", facebook_id: "99999", sign_in_count: 1, state: "disabled"
    Given I login with facebook as "facebook_guy"
    Then I should be on the login page
    And I should see "Login failed"
