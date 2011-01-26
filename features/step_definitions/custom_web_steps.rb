When(/^I select the option containing "([^\"]*)" in the autocomplete list$/) do |text|
  find("li a:contains('#{text}')").click
end

When /^I click "([^"]*)"$/ do |id|
  page.find(id).click
end
