Given /^location "([^"]*)" is tagged with "([^"]*)"$/ do |name, tag_names|
  location  = Location.find_by_name!(name)
  tag_names = tag_names.split(',').map(&:strip)
  location.tag_list.add(tag_names)
  location.save
end
