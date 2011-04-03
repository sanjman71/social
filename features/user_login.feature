Feature: User Login
  As a user
  I want to login with my facebook account

  Background:
    Given a city: "Chicago" should exist with name: "Chicago"

  @login
  Scenario: Member should be allowed to login and sent to home page by default
    Given a user "Facebook G." exists with handle: "Facebook G.", gender: "Male", orientation: "Straight", member: "1", facebook_id: "99999", city: city "Chicago", sign_in_count: 1
    And the facebook mock oauth has user "Facebook G." and email "facebooker@gmail.com" and id "99999"

    When I go to the login page
    And I follow "facebook_login"

    Then I should be on the home page
    And I should see "_gaq.push(['_trackPageview', '/login/completed'])"

  @login
  Scenario: User redirected to login page should return to requested page after login
    Given a user "Facebook G." exists with handle: "Facebook G.", gender: "Male", orientation: "Straight", member: "1", facebook_id: "99999", city: city "Chicago", sign_in_count: 1
    And the facebook mock oauth has user "Facebook G." and email "facebooker@gmail.com" and id "99999"

    When I go to "Facebook G."'s profile page
    Then I should be on the login page
    When I follow "facebook_login"

    Then I should be on "Facebook G."'s profile page
    And I should see "_gaq.push(['_trackPageview', '/login/completed'])"

  @login
  Scenario: Disabled users should not be allowed to login
    Given a user "Facebook G." exists with handle: "Facebook G.", gender: "Male", orientation: "Straight", member: "1", facebook_id: "99999", city: city "Chicago", sign_in_count: 1, state: "disabled"
    And the facebook mock oauth has user "Facebook G." and email "facebooker@gmail.com" and id "99999"

    When I go to the login page
    And I follow "facebook_login"

    Then I should be on the login page
    And I should see "Login failed"
