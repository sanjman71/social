Feature: User sends signup invitations
  As a user I want to send invitations to others to signup.
  
  Background:
    Given a user exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", member: "0"
    Then a user "chicago_guy" should exist with handle: "chicago_guy"
    And user "chicago_guy" has email "chicago_guy@outlately.com"
    And I am logged in as "chicago_guy"
  
  @javascript
  Scenario: User sends an invite to a new user's email address and the user accepts the invitation
    When I go to the invite page
    Then I should see "Invite Friends"
    And I fill in "search_invitee_autocomplete" with "invitee@outlately.com"
    And I wait for "3" seconds
    And I select the option containing "invitee@outlately.com" in the autocomplete list
    Then I should see "invitee@outlately.com" within "div#to span#display"
    And I press "Send"
    Then I should see "Sent Invitation"
    And the delayed jobs are processed
    Then "invitee@outlately.com" should receive an email with subject "Outlately Invitation!"
    And I go to the logout page
    And I open the email
    Then I should see "chicago_guy invited you to join Outlately." in the email body
    And I follow "here" in the email
    Then I should be on the login page

  @javascript
  Scenario: User sends an invite to an non-member user's email address
    When I go to the invite page
    Then I should see "Invite Friends"
    And I fill in "search_invitee_autocomplete" with "chicago_guy"
    And I wait for "3" seconds
    And I select the option containing "chicago_guy <chicago_guy@outlately.com>" in the autocomplete list
    Then I should see "chicago_guy <chicago_guy@outlately.com>" within "div#to span#display"
    And I press "Send"
    Then I should see "Sent Invitation"
    And the delayed jobs are processed
    Then "chicago_guy@outlately.com" should receive an email with subject "Outlately Invitation!"

  @javascript
  Scenario: User sends an invite to an invited user's email address
    Given user "chicago_guy" invited "friendly@gmail.com"
    And the delayed jobs are deleted
    When I go to the invite page
    Then I should see "Invite Friends"
    And I fill in "search_invitee_autocomplete" with "friend"
    And I wait for "3" seconds
    And I select the option containing "friendly@gmail.com" in the autocomplete list
    Then I should see "friendly@gmail.com" within "div#to span#display"
    And I press "Send"
    Then I should see "Sent Invitation"
    And the delayed jobs are processed
    Then "friendly@gmail.com" should receive an email with subject "Outlately Invitation!"
