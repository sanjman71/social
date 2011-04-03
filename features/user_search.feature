Feature: User Search
  As an user
  I want to search for other users

  Background:
    Given a user "Sanjay K." exists with handle: "Sanjay K.", gender: "Male", orientation: "Straight", member: "1"
    And user "Sanjay K." has email "sanjay@outlately.com"

  @search
  Scenario: Users should see random members
    Given a user "User1 L." exists with handle: "User1 L.", gender: "Male", orientation: "Straight", member: "1"
    Given a user "User2 L." exists with handle: "User2 L.", gender: "Male", orientation: "Straight", member: "0"

    And I am logged in as "Sanjay K."
    And I go to the search page

    # should see members only
    Then I should see "Search"
    And I should see "User1 L."
    And I should not see "User2 L."

  @search
  Scenario: Users should be able to search for members
    Given a user "Abbie L." exists with handle: "Ashton L.", gender: "Female", orientation: "Straight", member: "1"
    Given a user "Zeek L." exists with handle: "Zeek L.", gender: "Male", orientation: "Straight", member: "1"

    And I am logged in as "Sanjay K."
    And I go to the search page

    When I fill in "live_user_search" with "ze"
    And I wait for "2" seconds
    Then I should see "Zeek L."
    And I should not see "Abbie L."
    