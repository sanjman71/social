Feature: Import user checkin
  As a user I want to receive notifications when I check in using facebook or foursquare

  Scenario: Member should receive an email after a recent checkin is imported
    Given a user "sanjay" exists with handle: "sanjay", member: "1", gender: "Male", orientation: "Straight"
    And user "sanjay" has email "sanjay@outlately.com"
    And a location "Starbucks" exists with name: "Starbucks", city_state: "Chicago:IL", lat: "41.8781136", lng: "-87.6297982"
    And a checkin exists with user: user "sanjay", location: location "Starbucks", checkin_at: "#{3.hours.ago}", source_id: "1", source_type: "foursquare"
    And the delayed jobs are processed
    Then "sanjay@outlately.com" should receive an email with subject "Outlately: You checked in at Starbucks"
    When I open the email
    Then I should see "That checkin got you 10 points." in the email body

  @checkin
  Scenario: Member should receive an email after a recent checkin with other user checkins
    Given a user "sanjay" exists with handle: "sanjay", member: "1", gender: "Male"
    And user "sanjay" has email "sanjay@outlately.com"
    Given a user "coffee_gal1" exists with handle: "coffee_gal1", member: "1", gender: "Female", orientation: "Straight"
    Given a user "coffee_gal2" exists with handle: "coffee_gal2", member: "0", gender: "Female", orientation: "Straight"
    And a location "Starbucks" exists with name: "Starbucks", city_state: "Chicago:IL", lat: "41.8781136", lng: "-87.6297982"
    And a checkin exists with user: user "coffee_gal1", location: location "Starbucks", checkin_at: "#{1.day.ago}", source_id: "1", source_type: "foursquare"
    And a checkin exists with user: user "coffee_gal2", location: location "Starbucks", checkin_at: "#{2.days.ago}", source_id: "1", source_type: "foursquare"
    And sphinx is indexed
    And a checkin exists with user: user "sanjay", location: location "Starbucks", checkin_at: "#{10.minutes.ago}", source_id: "1", source_type: "foursquare"
    And the delayed jobs are processed

    Then "sanjay@outlately.com" should receive an email with subject "Outlately: Check out who else is out and about..."
    When I open the email with subject "Outlately: Check out who else is out and about..."
    Then I should see "coffee_gal1" in the email body
    And I should see "coffee_gal2" in the email body

  Scenario: Member should not receive an email when a older checkin is imported
    Given a user "sanjay" exists with handle: "sanjay", member: "1"
    And user "sanjay" has email "sanjay@outlately.com"
    And a location "Starbucks" exists with name: "Starbucks", city_state: "Chicago:IL", lat: "41.8781136", lng: "-87.6297982"
    And a checkin exists with user: user "sanjay", location: location "Starbucks", checkin_at: "#{12.hours.ago-1.minute}", source_id: "1", source_type: "foursquare"
    And the delayed jobs are processed
    Then "sanjay@outlately.com" should have no emails
  
  Scenario: Non-member should not receive emails for any imported checkins
    Given a user "sanjay" exists with handle: "sanjay", member: "0"
    And user "sanjay" has email "sanjay@outlately.com"
    And a location "Starbucks" exists with name: "Starbucks", city_state: "Chicago:IL", lat: "41.8781136", lng: "-87.6297982"
    And a checkin exists with user: user "sanjay", location: location "Starbucks", checkin_at: "#{1.hour.ago}", source_id: "1", source_type: "foursquare"
    And the delayed jobs are processed
    Then "sanjay@outlately.com" should have no emails
  