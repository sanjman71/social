Feature: Home Streams
  As a user I want to see streams of user activity

  @no-txn
  Scenario: User sees users in default Outlately stream
    Given a user "chicago_guy" in "Chicago, IL" who is a "straight" "male"
    And a user "chicago_coffee_gal" in "Chicago, IL" who is a "straight" "female"
    And a user "chicago_coffee_guy" in "Chicago, IL" who is a "straight" "male"
    And "chicago_coffee_gal" checked in to "Chicago Starbucks" in "Chicago"
    And "chicago_coffee_guy" checked in to "Chicago Lavazza" in "Chicago"
    And I am logged in as "chicago_guy"
    When sphinx is indexed
    When I go to the home page
    Then I should see "Outlately" within "span.current.stream_name"
    And I should see "chicago_coffee_gal" within "div.stream#outlately"
    And I should see "chicago_coffee_guy" within "div.stream#outlately"

  @no-txn
  Scenario: User sees users marked as available now in Today stream
    Given a user "chicago_guy" in "Chicago, IL" who is a "straight" "male"
    And a user "chicago_coffee_gal" in "Chicago, IL" who is a "straight" "female"
    And a user "chicago_coffee_guy" in "Chicago, IL" who is a "straight" "male"
    And "chicago_coffee_gal" checked in to "Chicago Starbucks" in "Chicago"
    And "chicago_coffee_guy" checked in to "Chicago Lavazza" in "Chicago"
    And "chicago_coffee_gal" marked themselves as available now
    And I am logged in as "chicago_guy"
    When sphinx is indexed
    When I go to the home page
    And I follow "Today"
    Then I should see "Today" within "span.current.stream_name"
    And I should see "chicago_coffee_gal" within "div.stream#today"
    And I should not see "chicago_coffee_guy" within "div.stream#today"

  @no-txn
  Scenario: User without a location is redirected to user edit page
    Given a user "chicago_guy" who is a "straight" "male"
    And I am logged in as "chicago_guy"
    When sphinx is indexed
    When I go to the home page
    Then I should be on chicago_guy's user edit page
    And I should see "My Profile" within "div.mat"
