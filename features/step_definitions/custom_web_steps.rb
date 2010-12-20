When(/^I select the option containing "([^\"]*)" in the autocomplete list$/) do |text|
  find("li a:contains('#{text}')").click
end