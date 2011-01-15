Feature: User sends signup invitations
  As a user I want to send invitations to others to signup.
  
  Background:
    Given a user "chicago_guy" exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", member: "1"
    And user "chicago_guy" has email "chicago_guy@outlately.com"
    And I am logged in as "chicago_guy"

  @javascript
  Scenario: User sends an invite to a new user's email address and the user accepts the invitation
    When I go to the invite page
    Then I should see "Invite Friends"
    And I fill in "invitees" with "invitee@outlately.com"
    And I press "Send"
    Then I should see "Sent Invitation."
    And the delayed jobs are processed
    And I go to the logout page

    Then "invitee@outlately.com" should receive an email with subject "chicago_guy invited you to Outlately!"
    And I open the email
    Then I should see "Outlately is a community" in the email body
    And I follow "here" in the email
    Then I should be on the login page

  @javascript
  Scenario: User tries to send an invite to an outlately member
    When I go to the invite page
    Then I should see "Invite Friends"
    And I fill in "invitees" with "chicago_guy@outlately.com"
    And I press "Send"
    Then I should see "No Invitations Sent. There is already a member with email chicago_guy@outlately.com"
