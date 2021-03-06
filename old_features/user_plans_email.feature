Feature: User's planned checkins
  In order to keep users engaged and informed
  As a user
  I want to receive emails for expiring, completed and expired plans

  Background:
    Given a city: "Chicago" should exist with name: "Chicago"
    And a state: "IL" should exist with code: "IL"
    And a user "chicago_guy" exists with handle: "chicago_guy", gender: "Male", orientation: "Straight", city: city "Chicago", member: "1"
    And user "chicago_guy" has email "chicago_guy@outlately.com"
    And a location "Chicago Starbucks" exists with name: "Chicago Starbucks", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"
    And a location "Chicago Lavazza" exists with name: "Chicago Lavazza", city: city "Chicago", state: state "IL", lat: "41.8781136", lng: "-87.6297982"

  @todo @email
  Scenario: User should receive exactly 1 email reminder a few days before a planned checkin expires
    Given a planned_checkin exists with user: user "chicago_guy", location: location "Chicago Starbucks", planned_at: "#{5.days.ago+1.minute}"
    And planned checkin reminders are sent
    And the resque jobs are processed
    Then "chicago_guy@outlately.com" should receive an email with subject "Outlately: Your planned checkin at Chicago Starbucks is about to expire"
    When I open the email with subject "Outlately: Your planned checkin at Chicago Starbucks is about to expire"
    Then I should see "Time is running out to checkin at Chicago Starbucks. You get 50 points for doing it!" in the email body
    # should not send another reminder
    When no emails have been sent
    And planned checkin reminders are sent
    And the resque jobs are processed
    Then "chicago_guy@outlately.com" should receive no emails with subject "Outlately: Your planned checkin at Chicago Starbucks is about to expire"

  @todo @email
  Scenario: User should receive an email after completing a planned checkin
    Given a planned_checkin exists with user: user "chicago_guy", location: location "Chicago Starbucks", planned_at: "#{3.days.ago}"
    And user "chicago_guy" checked in to "Chicago Starbucks" "3 hours ago"
    And the delayed jobs are processed
    And the resque jobs are processed
    Then "chicago_guy@outlately.com" should receive an email with subject "Outlately: Your planned checkin at Chicago Starbucks was completed!"
    When I open the email with subject "Outlately: Your planned checkin at Chicago Starbucks was completed!"
    Then I should see "You said you'd checkin at Chicago Starbucks and you did. That checkin got you 50 points." in the email body

  @todo @email
  Scenario: User should receive an email after a planned checkin expires
    Given a planned_checkin exists with user: user "chicago_guy", location: location "Chicago Starbucks", planned_at: "#{5.days.ago}"
    And 3 days have passed
    And planned checkins are expired
    And the resque jobs are processed
    Then "chicago_guy@outlately.com" should receive an email with subject "Outlately: Your planned checkin at Chicago Starbucks expired"
    When I open the email with subject "Outlately: Your planned checkin at Chicago Starbucks expired"
    Then I should see "Your planned checkin expired.  That cost you 10 points" in the email body
  