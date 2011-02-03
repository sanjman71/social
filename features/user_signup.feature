Feature: User Signup
  As an admin
  I want to track user signups

  Background:
    Given a city: "Chicago" should exist with name: "Chicago"
    And a state: "IL" should exist with code: "IL"

  @signup @goal
  Scenario: New user signup should complete the signup goal
    Given I login with facebook as "facebook_guy"
    Then I should be on the settings page
    And I should see "_gaq.push(['_trackPageview', '/signup/completed'])"
    And I should see "First L." within "div#me"

  @signup @goal
  Scenario: Non-member signup should complete the signup goal
    Given a user "facebook_guy" exists with handle: "facebook_guy", gender: "Male", orientation: "Straight", member: "0", facebook_id: "99999", city: city "Chicago"
    And 7 days have passed
    Given I login with facebook as "facebook_guy"
    Then I should be on the settings page
    And I should see "_gaq.push(['_trackPageview', '/signup/completed'])"
    And I should see "First L." within "div#me"
    # logging in a second time should not trigger the signup goal
    And I go to the logout page
    And I login with facebook as "facebook_guy"
    Then I should be on the home page
    And I should not see "_gaq.push(['_trackPageview', '/signup/completed'])"
    And I should not see "_gaq.push(['_trackPageview', '/signup/invited'])"

  @signup @email
  Scenario: New user signup should send email to site admins
    Given I login with facebook as "facebook_guy"
    And the resque jobs are processed
    Then "sanjay@jarna.com" should receive an email with subject "Outlately: member signup"
    And "marchick@gmail.com" should receive an email with subject "Outlately: member signup"

  @signup @javascript
  Scenario: New user signup should walk user through newbie signup process
    Given I login with facebook as "First L."
    And the resque jobs are cleared
    And user "First L." has city "Chicago"
    # And user "First L." has birthdate "Jan 15 1991"
    # Then I should be on path "/newbie/settings"
    And I go to path "/newbie/settings"
    Then I should see "My Settings"
    And I should see "Step 1 of 3:"
    And I should see "_gaq.push(['_trackPageview', '/newbie/1'])"
    And the "user_email" field should equal "facebook_guy@gmail.com"
    And the "user_city_name" field should equal "Chicago, IL"
    And I select "January" from "user_birthdate_2i"
    And I select "15" from "user_birthdate_3i"
    And I select "1991" from "user_birthdate_1i"
    And I wait for "1" second
    And I press "Next"

    Then I should be on path "/newbie/favorites"
    Then I should see "Favorite Places"
    And I should see "Step 2 of 3:"
    And I should see "_gaq.push(['_trackPageview', '/newbie/2'])"
    And I fill in "search_places_autocomplete" with "Paramount Room"
    And I wait for "3" seconds
    And I select the option containing "Paramount Room" in the autocomplete list
    And I follow "Next"
    # should follow js redirect
    And I wait for "1" second
    Then I should be on path "/newbie/plans"

    And the resque jobs are processed
    Then "facebook_guy@gmail.com" should receive an email with subject "Outlately: You marked Paramount Room as a favorite place..."
    And I open the email
    Then I should see "Each time you checkin, you'll receive an email like this that includes similar checkins from other users." in the email body

    And I should see "Planned Checkins"
    And I should see "Step 3 of 3:"
    And I should see "_gaq.push(['_trackPageview', '/newbie/3'])"
    And I fill in "search_places_autocomplete" with "dmk burger"
    And I wait for "3" seconds
    And I select the option containing "DMK Burger Bar" in the autocomplete list
    And I fill in "going" with tomorrow
    And I follow "Next"
    # should follow js redirect
    And I wait for "1" second
    Then I should be on path "/"
    And I should see "_gaq.push(['_trackPageview', '/newbie/completed'])"

    And the resque jobs are processed
    Then "facebook_guy@gmail.com" should receive an email with subject "Outlately: You planned a checkin at DMK Burger Bar..."
    And I open the email with subject "Outlately: You planned a checkin at DMK Burger Bar..."
    Then I should see "Your planned checkin is in 1 day." in the email body

