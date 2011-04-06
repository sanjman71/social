Feature: User sends signup invitations
  In order to increase traffic and adoption,
  As a user
  I want to send invitations to others to signup and receive notifications when do sign up.
  
  Background:
    Given a user "chicago_guy" exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", member: "1"
    And user "chicago_guy" has email "chicago_guy@outlately.com"
    And the resque jobs are reset

  @invite @email
  Scenario: User sends an invite and the invitation is accepted
    Given I am logged in as "chicago_guy"
    When I go to the invite page
    Then I should see "Invite Friends"
    And I fill in "invitees" with "invitee@gmail.com"
    And I press "Send"
    Then I should see "Sent Invitation."
    And I should see "_gaq.push(['_trackPageview', '/action/invite/message'])"

    # logout
    And the resque jobs are processed
    And I go to the logout page

    Then "invitee@gmail.com" should receive an email with subject "Follow me on Outlate.ly!"
    And I open the email
    Then I should see "Hey, I want to make it easier for us to meet up" in the email body
    And I follow "here" in the email
    Then I should be on the login page

    # user facebook signup
    When the facebook mock oauth has user "Invitee L." and email "invitee@gmail.com" and id "99999"
    And I follow "facebook_login"
    And the resque jobs are processed

    Then I should be on path "/newbie/settings"
    And I should see "_gaq.push(['_trackPageview', '/signup/completed'])"
    And I should see "_gaq.push(['_trackPageview', '/signup/invited'])"

    And "chicago_guy@outlately.com" should receive an email with subject "Outlate.ly: Your invitation was accepted!"
    And I open the email with subject "Outlate.ly: Your invitation was accepted!"
    Then I should see "Your friend Invitee L. just signed up." in the email body
    And I should see "Thanks for inviting them." in the email body

    # invitee should auto follow inviter
    And "chicago_guy@outlately.com" should receive an email with subject "Outlate.ly: Invitee L. is now following you"

  @invite @email
  Scenario: User sends an invite because they were poked and the invitation is accepted
    Given I am logged in as "chicago_guy"

    And a user "Chicago H." exists with handle: "Chicago H.", gender: "Female", orientation: "Straight", member: "0", points: "0", facebook_id: "88888"
    And user "Chicago H." has email "chicago_hottie@outlately.com"
    And "chicago_guy" is friends with "Chicago H."

    And a user "chicago_guy1" exists with handle: "chicago_guy1", gender: "Male", orientation: "Straight", member: "1", points: "0"
    And user "chicago_guy1" has email "chicago_guy1@outlately.com"

    And a user "chicago_guy2" exists with handle: "chicago_guy2", gender: "Male", orientation: "Straight", member: "1", points: "0"
    And user "chicago_guy2" has email "chicago_guy2@outlately.com"

    And user "chicago_guy1" poked "chicago_guy" to invite "Chicago H."
    And user "chicago_guy2" poked "chicago_guy" to invite "Chicago H."

    When I go to the invite page
    And I fill in "invitees" with "chicago_hottie@outlately.com"
    And I press "Send"
    Then I should see "Sent Invitation."
    And I should see "_gaq.push(['_trackPageview', '/action/invite/message'])"
    And the resque jobs are processed
    And I go to the logout page

    Then "chicago_hottie@outlately.com" should receive an email with subject "Follow me on Outlate.ly!"
    And I open the email with subject "Follow me on Outlate.ly!"
    Then I should see "Hey, I want to make it easier for us to meet up" in the email body
    And I follow "here" in the email
    Then I should be on the login page

    # user facebook signup
    When the facebook mock oauth has user "Chicago H." and email "chicago_hottie@outlately.com" and id "88888"
    And I follow "facebook_login"
    And the resque jobs are processed until empty

    Then I should be on path "/newbie/settings"
    And I should see "_gaq.push(['_trackPageview', '/signup/completed'])"
    And I should see "_gaq.push(['_trackPageview', '/signup/invited'])"

    And "chicago_guy@outlately.com" should receive an email with subject "Outlate.ly: Your invitation was accepted!"
    And "chicago_guy1@outlately.com" should receive an email with subject "Outlate.ly: You might be interested in this user signup..."
    And "chicago_guy2@outlately.com" should receive an email with subject "Outlate.ly: You might be interested in this user signup..."

  @invite
  Scenario: User tries to invite an existing outlately member
    Given I am logged in as "chicago_guy"
    And I go to the invite page
    Then I should see "Invite Friends"
    And I fill in "invitees" with "chicago_guy@outlately.com"
    And I press "Send"
    Then I should see "No Invitations Sent. There is already a member with the email chicago_guy@outlately.com"
    And I should not see "_gaq.push(['_trackPageview', '/action/invite/message'])"
