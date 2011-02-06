When(/^I select the option containing "([^\"]*)" in the autocomplete list$/) do |text|
  find("li a:contains('#{text}')").click
end

When /^I click "([^"]*)"$/ do |id|
  page.find(id).click
end

Then /^the "([^"]*)" field(?: within "([^\"]*)")? should(not )? equal "([^"]*)"$/ do |field, selector, negate, value|
  expectation = negate ? :should_not : :should
  with_scope(selector) do
    field = find_field(field)
    field_value = (field.tag_name == 'textarea') ? field.text : field.value
    field_value.send(expectation) == value
  end
end

Then /^I should see "([^"]*)" within "([^"]*)" count "([^"]*)"$/ do |text, selector, count|
  assert page.has_css?(selector, :text => text, :count => count.to_i)
end

