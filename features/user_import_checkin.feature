Feature: Import user checkin
  As a user I want to see my checkins and receive notifications when I check in

  Scenario: Member should receive an email when a recent checkin is imported
    Given a user exists with handle: "sanjay", member: "1"
    And user "sanjay" has email "sanjay@outlately.com"
    Then a user: "sanjay" should exist with handle: "sanjay"
    And a location exists with name: "Starbucks", city_state: "Chicago:IL", lat: "41.8781136", lng: "-87.6297982"
    Then a location: "Starbucks" should exist with name: "Starbucks"
    And a checkin exists with user: user "sanjay", location: location "Starbucks", checkin_at: "#{3.hours.ago}", source_id: "1", source_type: "foursquare"
    And the delayed jobs are processed
    Then "sanjay@outlately.com" should receive an email with subject "You checked in at Starbucks"
    When I open the email
    Then I should see "That checkin got you 10 points." in the email body

  Scenario: Member should not receive an email when a older checkin is imported
    Given a user exists with handle: "sanjay", member: "1"
    And user "sanjay" has email "sanjay@outlately.com"
    Then a user: "sanjay" should exist with handle: "sanjay"
    And a location exists with name: "Starbucks", city_state: "Chicago:IL", lat: "41.8781136", lng: "-87.6297982"
    Then a location: "Starbucks" should exist with name: "Starbucks"
    And a checkin exists with user: user "sanjay", location: location "Starbucks", checkin_at: "#{12.hours.ago-1.minute}", source_id: "1", source_type: "foursquare"
    And the delayed jobs are processed
    Then "sanjay@outlately.com" should have no emails

  Scenario: Non-member should not receive emails for any imported checkins
    Given a user exists with handle: "sanjay", member: "0"
    And user "sanjay" has email "sanjay@outlately.com"
    Then a user: "sanjay" should exist with handle: "sanjay"
    And a location exists with name: "Starbucks", city_state: "Chicago:IL", lat: "41.8781136", lng: "-87.6297982"
    Then a location: "Starbucks" should exist with name: "Starbucks"
    And a checkin exists with user: user "sanjay", location: location "Starbucks", checkin_at: "#{1.hour.ago}", source_id: "1", source_type: "foursquare"
    And the delayed jobs are processed
    Then "sanjay@outlately.com" should have no emails
  