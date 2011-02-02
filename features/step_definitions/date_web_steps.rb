DATE_TIME_SUFFIXES = {
  :year   => '1i',
  :month  => '2i',
  :day    => '3i',
  :hour   => '4i',
  :minute => '5i'
}

def select_date(date_to_select, options = {})
  date = Date.parse(date_to_select)
  id_prefix = id_prefix_for(options)

  select date.year.to_s,      :from => "#{id_prefix}_#{DATE_TIME_SUFFIXES[:year]}"
  select date.day.to_s,       :from => "#{id_prefix}_#{DATE_TIME_SUFFIXES[:day]}"
  select date.strftime('%b'), :from => "#{id_prefix}_#{DATE_TIME_SUFFIXES[:month]}"
end

def select_time(time_to_select, options = {})
  time = Time.parse(time_to_select)
  id_prefix = id_prefix_for(options)

  select time.hour.to_s, :from => "#{id_prefix}_#{DATE_TIME_SUFFIXES[:hour]}"
  select time.min.to_s,  :from => "#{id_prefix}_#{DATE_TIME_SUFFIXES[:minute]}"
end

def select_datetime(datetime_to_select, options = {})
  select_date(datetime_to_select, options)
  select_time(datetime_to_select, options)
end

def id_prefix_for(options = {})
  find('label', :text => options[:on])[:for]
end

When /^(?:|I )select "([^\"]*)" as the date$/ do |date|
  select_date(date, :on => 'date')
end

When /^(?:|I )select "([^\"]*)" as the time/ do |time|
  select_time(time, :on => 'time')
end

When /^(?:|I )select "([^\"]*)" as the "([^\"]*)" date$/ do |date, field|
  select_date(date, :on => field)
end

When /^(?:|I )select "([^\"]*)" as the "([^\"]*)" time/ do |time, field|
  select_time(time, :on => field)
end

When /^(?:|I )select "([^\"]*)" as the date and time$/ do |datetime|
  select_datetime(datetime, :on => 'date')
end

When /^(?:|I )select "([^\"]*)" as the "([^\"]*)" date and time$/ do |datetime, field|
  select_datetime(datetime, :on => field)
end