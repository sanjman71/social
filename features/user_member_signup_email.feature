Feature: Emails are sent when a user signs up
  As an admin
  I want to be notified when a member signs up

  Scenario:
    Given a user "chicago_guy" exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", member: "1", points: "0"
    Then "sanjay@jarna.com" should receive an email with subject "Outlately: member signup chicago_guy"
    