Feature: Import user checkin
  As a user
  I want to receive notifications when I checkin using facebook or foursquare

  Background:
    Given a user "sanjay" exists with handle: "sanjay", member: "1", gender: "Male", orientation: "Straight"
    And user "sanjay" has email "sanjay@outlately.com"
    And user "sanjay" has oauth "facebook" "123"

    And a user "adam" exists with handle: "adam", member: "1", gender: "Male", orientation: "Straight"
    And user "adam" has email "adam@outlately.com"

    And a user "friendly" exists with handle: "friendly", member: "1", gender: "Male", orientation: "Straight"
    And user "friendly" has email "friendly@gmail.com"

    And a location "Starbucks" exists with name: "Starbucks", street_address: "200 N State St.", city_state: "Chicago:IL", lat: "41.8781136", lng: "-87.6297982"

  @checkin @email @realtime
  Scenario: Members who have opted in should receive an email after a recent checkin is imported
    Given user "sanjay" has preference "preferences_import_checkin_emails" "1"
    And user "sanjay" checked in to "Starbucks" "3 hours ago"
    And the resque jobs are processed

    Then "sanjay@outlately.com" should receive an email with subject "Outlately: You checked in at Starbucks"
    When I open the email
    Then I should see "Good work. That checkin got you 10 points." in the email body


  @checkin @email @realtime
  Scenario: Followers should receive an email after a user checkin is imported
    Given "adam" is friends with "sanjay"
    And "adam" is friends with "friendly"
    And "sanjay" is following "adam"

    And user "adam" checked in to "Starbucks" "5 minutes ago"
    And the resque jobs are processed until empty

    # friends shouldn't receive emails
    Then "friendly@gmail.com" should receive no emails with subject "Outlate.ly: adam checked in at Starbucks..."

    # followers should receive emails
    And "sanjay@outlately.com" should receive an email with subject "Outlate.ly: adam checked in at Starbucks..."
    When I open the email with subject "Outlate.ly: adam checked in at Starbucks..."
    Then I should see "Just wanted to let you know that adam checked in at Starbucks, 200 N State St., Chicago, IL" in the email body
    And I should see "Be There Soon" in the email body
    And I should see "Love That Place" in the email body
    And I should see "Send a Message" in the email body


  @checkin @email @realtime
  Scenario: Users should be able to respond to a checkin email with 'be there soon'
    Given "sanjay" is following "adam"
    And user "adam" checked in to "Starbucks" "5 minutes ago"
    And the resque jobs are processed until empty
    Then "sanjay@outlately.com" should receive an email with subject "Outlate.ly: adam checked in at Starbucks..."

    When I open the email with subject "Outlate.ly: adam checked in at Starbucks..."
    And I follow "Be There Soon" in the email
    Then I should see "_gaq.push(['_trackPageview', '/action/message/bts'])"
    And I press "Send"
    Then I should see "Sent message"

    When the resque jobs are processed
    Then "adam@outlately.com" should receive an email with subject "Outlate.ly: sanjay sent you a message about your checkin at Starbucks..."
    When I open the email with subject "Outlate.ly: sanjay sent you a message about your checkin at Starbucks..."
    Then I should see "I'll be there soon" in the email body


  @checkin @email @realtime
  Scenario: Users should be able to respond to a checkin email with 'love that place'
    Given "sanjay" is following "adam"
    And user "adam" checked in to "Starbucks" "5 minutes ago"
    And the resque jobs are processed until empty
    Then "sanjay@outlately.com" should receive an email with subject "Outlate.ly: adam checked in at Starbucks..."

    When I open the email with subject "Outlate.ly: adam checked in at Starbucks..."
    And I follow "Love That Place" in the email
    Then I should see "_gaq.push(['_trackPageview', '/action/message/ltp'])"
    And I press "Send"
    Then I should see "Sent message"

    When the resque jobs are processed
    Then "adam@outlately.com" should receive an email with subject "Outlate.ly: sanjay sent you a message about your checkin at Starbucks..."
    When I open the email with subject "Outlate.ly: sanjay sent you a message about your checkin at Starbucks..."
    Then I should see "I love that place" in the email body


  @checkin @email @realtime
  Scenario: Users should be able to respond to a checkin email with free form text
    Given "sanjay" is following "adam"
    And user "adam" checked in to "Starbucks" "5 minutes ago"
    And the resque jobs are processed until empty
    Then "sanjay@outlately.com" should receive an email with subject "Outlate.ly: adam checked in at Starbucks..."

    When I open the email with subject "Outlate.ly: adam checked in at Starbucks..."
    When I follow "Compose Message" in the email
    Then I should see "_gaq.push(['_trackPageview', '/action/message/compose'])"
    And I fill in "message_body" with "Hey there!"
    And I press "Send"
    Then I should see "Sent message"

    When the resque jobs are processed
    Then "adam@outlately.com" should receive an email with subject "Outlate.ly: sanjay sent you a message about your checkin at Starbucks..."
    When I open the email with subject "Outlate.ly: sanjay sent you a message about your checkin at Starbucks..."
    Then I should see "Hey there!" in the email body

  # deprecated feature
  # @checkin @email @realtime
  # Scenario: Members who are marked as 'out' should receive an email with other realtime checkins
  #   Given a user "sanjay" exists with handle: "sanjay", member: "1", gender: "Male"
  #   And user "sanjay" has email "sanjay@outlately.com"
  #   Given a user "coffee_gal1" exists with handle: "coffee_gal1", member: "1", gender: "Female", orientation: "Straight"
  #   Given a user "coffee_gal2" exists with handle: "coffee_gal2", member: "0", gender: "Female", orientation: "Straight"
  #   And a location "Starbucks" exists with name: "Starbucks", city_state: "Chicago:IL", lat: "41.8781136", lng: "-87.6297982"
  #   And a location "Lavazza" exists with name: "Lavazza", city_state: "Chicago:IL", lat: "41.8781136", lng: "-87.6297982"
  #   And user "coffee_gal1" checked in to "Starbucks" "15 minutes ago"
  #   And user "coffee_gal2" checked in to "Starbucks" "17 minutes ago"
  #   And user "sanjay" checked in to "Starbucks" "5 minutes ago"
  #   And sphinx is indexed
  #   And the realtime checkin matches job is queued
  #   # process jobs twice
  #   And the resque jobs are processed
  #   And the resque jobs are processed again
  # 
  #   # only members should get emails
  #   Then "sanjay@outlately.com" should receive an email with subject "Outlately: Who's out and about Starbucks right now..."
  #   And "coffee_gal1@outlately.com" should receive no emails with subject "Outlately: Who's out and about Starbucks right now..."
  #   And "coffee_gal2@outlately.com" should receive no emails with subject "Outlately: Who's out and about Starbucks right now..."
  #   When "sanjay@outlately.com" open the email with subject "Outlately: Who's out and about Starbucks right now..."
  #   Then I should see "Thanks for checking in at Starbucks." in the email body
  #   And I should see "coffee_gal1" in the email body
  #   And I should see "coffee_gal2" in the email body
  #   And I should see "Share a Drink" in the email body
  #   And I should see "utm_campaign" in the email body
  # 
  #   # another check should not generate an email with the same realtime checkins
  #   And user "sanjay" checked in to "Lavazza" "2 minutes ago"
  #   And a clear email queue
  #   And sphinx is indexed
  #   And the realtime checkin matches job is queued
  #   And the resque jobs are processed
  #   And the resque jobs are processed again
  #   Then "sanjay@outlately.com" should receive no emails with subject "Outlately: Who's out and about Starbucks right now..."
  # 
  #   # a new checkin within the 'out' window should generate an email
  #   And user "coffee_gal1" checked in to "Lavazza" "3 minutes ago"
  #   And sphinx is indexed
  #   And the realtime checkin matches job is queued
  #   And the resque jobs are processed
  #   And the resque jobs are processed again
  #   Then "sanjay@outlately.com" should receive an email with subject "Outlately: Who's out and about Starbucks right now..."
  #   When I open the email with subject "Outlately: Who's out and about Starbucks right now..."
  #   Then I should see "Thanks for checking in at Starbucks." in the email body
  #   And I should see "coffee_gal1" in the email body
  #   And I should see "Lavazza" in the email body
  # 
  #   # a new checkin outside of the 'out' window should not generate an email
  #   Given 2 hours has passed
  #   And user "coffee_gal2" checked in to "Lavazza" "30 minutes ago"
  #   And a clear email queue
  #   And sphinx is indexed
  #   And the realtime checkin matches job is queued
  #   And the resque jobs are processed
  #   And the resque jobs are processed again
  #   Then "sanjay@outlately.com" should receive no emails with subject "Outlately: Who's out and about Starbucks right now..."

  # deprecated feature
  # @checkin @email @daily
  # Scenario: Members should receive a daily checkins email the day after they checkin
  #   Given a user "sanjay" exists with handle: "sanjay", member: "1", gender: "Male"
  #   And user "sanjay" has email "sanjay@outlately.com"
  #   Given a user "coffee_gal1" exists with handle: "coffee_gal1", member: "1", gender: "Female", orientation: "Straight"
  #   Given a user "coffee_gal2" exists with handle: "coffee_gal2", member: "0", gender: "Female", orientation: "Straight"
  #   And a location "Starbucks" exists with name: "Starbucks", city_state: "Chicago:IL", lat: "41.8781136", lng: "-87.6297982"
  #   And user "coffee_gal1" checked in to "Starbucks" "1 day ago"
  #   And user "coffee_gal2" checked in to "Starbucks" "2 days ago"
  #   And user "sanjay" checked in to "Starbucks" "10 minutes ago"
  #   And sphinx is indexed
  #   And the resque jobs are processed
  #   And the resque jobs are processed again
  #   Then "sanjay@outlately.com" should receive no emails with subject "Outlately: Your daily checkin email..."
  # 
  #   # the daily checkin email should be sent the following day
  #   Given 1 day has passed
  #   And sphinx is indexed
  #   And the daily checkin matches job is queued
  #   And the resque jobs are processed until empty
  #   Then "sanjay@outlately.com" should receive an email with subject "Outlately: Your daily checkin email..."
  #   When I open the email with subject "Outlately: Your daily checkin email..."
  #   Then I should see "We noticed your checkin at Starbucks yesterday." in the email body
  #   And I should see "coffee_gal1" in the email body
  #   And I should see "coffee_gal2" in the email body

  @checkin @email
  Scenario: Member should not receive an email when an old checkin is imported
    Given a user "sanjay" exists with handle: "sanjay", member: "1"
    And user "sanjay" has email "sanjay@outlately.com"
    And a location "Starbucks" exists with name: "Starbucks", city_state: "Chicago:IL", lat: "41.8781136", lng: "-87.6297982"
    And a checkin exists with user: user "sanjay", location: location "Starbucks", checkin_at: "#{12.hours.ago-1.minute}", source_id: "1", source_type: "foursquare"
    And the resque jobs are processed
    Then "sanjay@outlately.com" should have no emails

  @checkin @email
  Scenario: Non-members should not receive emails for imported checkins
    Given a user "sanjay" exists with handle: "sanjay", member: "0"
    And user "sanjay" has email "sanjay@outlately.com"
    And a location "Starbucks" exists with name: "Starbucks", city_state: "Chicago:IL", lat: "41.8781136", lng: "-87.6297982"
    And a checkin exists with user: user "sanjay", location: location "Starbucks", checkin_at: "#{1.hour.ago}", source_id: "1", source_type: "foursquare"
    And the resque jobs are processed
    Then "sanjay@outlately.com" should have no emails
  