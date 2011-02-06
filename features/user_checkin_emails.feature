Feature: Import user checkin
  As a user I want to receive notifications when I check in using facebook or foursquare

  @checkin @email
  Scenario: Member should receive an email after a recent checkin is imported
    Given a user "sanjay" exists with handle: "sanjay", member: "1", gender: "Male", orientation: "Straight"
    And user "sanjay" has email "sanjay@outlately.com"
    And a location "Starbucks" exists with name: "Starbucks", city_state: "Chicago:IL", lat: "41.8781136", lng: "-87.6297982"
    And a checkin exists with user: user "sanjay", location: location "Starbucks", checkin_at: "#{3.hours.ago}", source_id: "1", source_type: "foursquare"
    And the resque jobs are processed
    Then "sanjay@outlately.com" should receive an email with subject "Outlately: You checked in at Starbucks"
    When I open the email
    Then I should see "Good work. That checkin got you 10 points." in the email body

  @checkin @email
  Scenario: Members who are marked as 'out' should receive an email with other realtime checkins
    Given a user "sanjay" exists with handle: "sanjay", member: "1", gender: "Male"
    And user "sanjay" has email "sanjay@outlately.com"
    Given a user "coffee_gal1" exists with handle: "coffee_gal1", member: "1", gender: "Female", orientation: "Straight"
    Given a user "coffee_gal2" exists with handle: "coffee_gal2", member: "0", gender: "Female", orientation: "Straight"
    And a location "Starbucks" exists with name: "Starbucks", city_state: "Chicago:IL", lat: "41.8781136", lng: "-87.6297982"
    And a location "Lavazza" exists with name: "Lavazza", city_state: "Chicago:IL", lat: "41.8781136", lng: "-87.6297982"
    And user "coffee_gal1" checked in to "Starbucks" "15 minutes ago"
    And user "coffee_gal2" checked in to "Starbucks" "17 minutes ago"
    And user "sanjay" checked in to "Starbucks" "5 minutes ago"
    And sphinx is indexed
    And the realtime checkin stream job is queued
    # process jobs twice
    And the resque jobs are processed
    And the resque jobs are processed
    # only members should get emails
    Then "sanjay@outlately.com" should receive an email with subject "Outlately: Who's out and about right now..."
    And "coffee_gal1@outlately.com" should receive no emails with subject "Outlately: Who's out and about right now..."
    And "coffee_gal2@outlately.com" should receive no emails with subject "Outlately: Who's out and about right now..."
    When "sanjay@outlately.com" open the email with subject "Outlately: Who's out and about right now..."
    Then I should see "Thanks for checking in at Starbucks." in the email body
    And I should see "coffee_gal1" in the email body
    And I should see "coffee_gal2" in the email body
    And I should see "Share a Drink" in the email body

    # another check should not generate an email with the same realtime checkins
    And user "sanjay" checked in to "Lavazza" "2 minutes ago"
    And a clear email queue
    And sphinx is indexed
    And the realtime checkin stream job is queued
    # process jobs twice
    And the resque jobs are processed
    And the resque jobs are processed
    Then "sanjay@outlately.com" should receive no emails with subject "Outlately: Who's out and about right now..."

    # a new checkin within the 'out' window should generate an email
    And user "coffee_gal1" checked in to "Lavazza" "3 minutes ago"
    And sphinx is indexed
    And the realtime checkin stream job is queued
    # process jobs twice
    And the resque jobs are processed
    And the resque jobs are processed
    Then "sanjay@outlately.com" should receive an email with subject "Outlately: Who's out and about right now..."
    When I open the email with subject "Outlately: Who's out and about right now..."
    Then I should see "Thanks for checking in at Starbucks." in the email body
    And I should see "coffee_gal1" in the email body
    And I should see "Lavazza" in the email body

    # a new checkin outside of the 'out' window should not generate an email
    Given 2 hours has passed
    And user "coffee_gal2" checked in to "Lavazza" "30 minutes ago"
    And a clear email queue
    And sphinx is indexed
    And the realtime checkin stream job is queued
    # process jobs twice
    And the resque jobs are processed
    And the resque jobs are processed
    Then "sanjay@outlately.com" should receive no emails with subject "Outlately: Who's out and about right now..."

  @checkin @email
  Scenario: Members should receive an email after a recent checkin with other matching checkins
    Given a user "sanjay" exists with handle: "sanjay", member: "1", gender: "Male"
    And user "sanjay" has email "sanjay@outlately.com"
    Given a user "coffee_gal1" exists with handle: "coffee_gal1", member: "1", gender: "Female", orientation: "Straight"
    Given a user "coffee_gal2" exists with handle: "coffee_gal2", member: "0", gender: "Female", orientation: "Straight"
    And a location "Starbucks" exists with name: "Starbucks", city_state: "Chicago:IL", lat: "41.8781136", lng: "-87.6297982"
    And user "coffee_gal1" checked in to "Starbucks" "1 day ago"
    And user "coffee_gal2" checked in to "Starbucks" "2 days ago"
    And sphinx is indexed
    And a checkin exists with user: user "sanjay", location: location "Starbucks", checkin_at: "#{10.minutes.ago}", source_id: "1", source_type: "foursquare"
    And the resque jobs are processed
    And the resque jobs are processed

    Then "sanjay@outlately.com" should receive an email with subject "Outlately: Check out who else is out and about..."
    When I open the email with subject "Outlately: Check out who else is out and about..."
    Then I should see "coffee_gal1" in the email body
    And I should see "coffee_gal2" in the email body

  Scenario: Member should not receive an email when a older checkin is imported
    Given a user "sanjay" exists with handle: "sanjay", member: "1"
    And user "sanjay" has email "sanjay@outlately.com"
    And a location "Starbucks" exists with name: "Starbucks", city_state: "Chicago:IL", lat: "41.8781136", lng: "-87.6297982"
    And a checkin exists with user: user "sanjay", location: location "Starbucks", checkin_at: "#{12.hours.ago-1.minute}", source_id: "1", source_type: "foursquare"
    And the resque jobs are processed
    Then "sanjay@outlately.com" should have no emails

  @checkin @email
  Scenario: Non-member should not receive emails for imported checkins
    Given a user "sanjay" exists with handle: "sanjay", member: "0"
    And user "sanjay" has email "sanjay@outlately.com"
    And a location "Starbucks" exists with name: "Starbucks", city_state: "Chicago:IL", lat: "41.8781136", lng: "-87.6297982"
    And a checkin exists with user: user "sanjay", location: location "Starbucks", checkin_at: "#{1.hour.ago}", source_id: "1", source_type: "foursquare"
    And the resque jobs are processed
    Then "sanjay@outlately.com" should have no emails
  