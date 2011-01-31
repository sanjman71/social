Feature: User Signup
  As an admin
  I want to track user signups

  Background:
    Given a city: "Chicago" should exist with name: "Chicago"

  @signup @goal
  Scenario: New user signup should complete the signup goal
    Given I login with facebook as "facebook_guy"
    Then I should be on the settings page
    And I should see "_gaq.push(['_trackPageview', '/signup/completed'])"
    And I should see "First L." within "div#me"

  @signup @email
  Scenario: New user signup should send emails to site admins
    Given I login with facebook as "facebook_guy"
    Then "sanjay@jarna.com" should receive an email with subject "Outlately: member signup"
    And "marchick@gmail.com" should receive an email with subject "Outlately: member signup"

  @signup @goal
  Scenario: Non-member signup should complete the signup goal
    Given a user "facebook_guy" exists with handle: "facebook_guy", gender: "Male", orientation: "Straight", member: "0", facebook_id: "99999", city: city "Chicago"
    And 7 days have passed
    Given I login with facebook as "facebook_guy"
    Then I should be on the settings page
    And I should see "_gaq.push(['_trackPageview', '/signup/completed'])"
    # logging in a second time should not trigger the signup goal
    And I go to the logout page
    And I login with facebook as "facebook_guy"
    Then I should be on the home page
    And I should not see "_gaq.push(['_trackPageview', '/signup/completed'])"
    And I should not see "_gaq.push(['_trackPageview', '/signup/invited'])"

    