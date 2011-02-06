Feature: User sends signup invitations
  In order to increase traffic and adoption,
  As a user
  I want to send invitations to others to signup and receive notifications when do sign up.
  
  Background:
    Given a user "chicago_guy" exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", member: "1"
    And user "chicago_guy" has email "chicago_guy@outlately.com"
    And I am logged in as "chicago_guy"
    And the resque jobs are reset

  @javascript @invite @email
  Scenario: User sends an invite and the invitation is accepted
    When I go to the invite page
    Then I should see "Invite Friends"
    And I fill in "invitees" with "invitee@outlately.com"
    And I press "Send"
    Then I should see "Sent Invitation."
    And I should see "_gaq.push(['_trackPageview', '/action/invite/message'])"
    And the resque jobs are processed
    And I go to the logout page

    Then "invitee@outlately.com" should receive an email with subject "Outlately: chicago_guy invited you to Outlately!"
    And I open the email
    Then I should see "Outlately is a community" in the email body
    And I follow "here" in the email
    Then I should be on the login page

    # user facebook signup
    And I login with facebook as "invitee"
    And the resque jobs are processed
    Then I should be on path "/newbie/settings"
    And I should see "_gaq.push(['_trackPageview', '/signup/completed'])"
    And I should see "_gaq.push(['_trackPageview', '/signup/invited'])"

    And "chicago_guy@outlately.com" should receive an email with subject "Outlately: Your invitation was accepted!"
    And I open the email with subject "Outlately: Your invitation was accepted!"
    Then I should see "You invited First L. and they signed up." in the email body

  @javascript @invite @email
  Scenario: User sends an invite because they were poked and the invitation is accepted
    Given a user "chicago_hottie" exists with handle: "chicago_hottie", gender: "Female", orientation: "Straight", member: "0", points: "0", facebook_id: "88888"
    And user "chicago_hottie" has email "chicago_hottie@outlately.com"
    And "chicago_guy" is friends with "chicago_hottie"
    And a user "chicago_guy1" exists with handle: "chicago_guy1", gender: "Male", orientation: "Straight", member: "1", points: "0"
    And user "chicago_guy1" has email "chicago_guy1@outlately.com"
    And a user "chicago_guy2" exists with handle: "chicago_guy2", gender: "Male", orientation: "Straight", member: "1", points: "0"
    And user "chicago_guy2" has email "chicago_guy2@outlately.com"
    And user "chicago_guy1" poked "chicago_guy" to invite "chicago_hottie"
    And user "chicago_guy2" poked "chicago_guy" to invite "chicago_hottie"

    When I go to the invite page
    And I fill in "invitees" with "chicago_hottie@outlately.com"
    And I press "Send"
    Then I should see "Sent Invitation."
    And I should see "_gaq.push(['_trackPageview', '/action/invite/message'])"
    And the resque jobs are processed
    And I go to the logout page

    Then "chicago_hottie@outlately.com" should receive an email with subject "Outlately: chicago_guy invited you to Outlately!"
    And I open the email with subject "Outlately: chicago_guy invited you to Outlately!"
    Then I should see "Outlately is a community" in the email body
    And I follow "here" in the email
    Then I should be on the login page

    # user facebook signup
    And I login with facebook as "chicago_hottie"
    And the resque jobs are processed
    Then I should be on path "/newbie/settings"
    And I should see "_gaq.push(['_trackPageview', '/signup/completed'])"
    And I should see "_gaq.push(['_trackPageview', '/signup/invited'])"

    And "chicago_guy@outlately.com" should receive an email with subject "Outlately: Your invitation was accepted!"
    And "chicago_guy1@outlately.com" should receive an email with subject "Outlately: You might be interested in this user signup..."
    And "chicago_guy2@outlately.com" should receive an email with subject "Outlately: You might be interested in this user signup..."

  @javascript @invitations
  Scenario: User tries to invite an existing outlately member
    When I go to the invite page
    Then I should see "Invite Friends"
    And I fill in "invitees" with "chicago_guy@outlately.com"
    And I press "Send"
    Then I should see "No Invitations Sent. There is already a member with email chicago_guy@outlately.com"
    And I should not see "_gaq.push(['_trackPageview', '/action/invite/message'])"
