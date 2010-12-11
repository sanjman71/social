class Users < Thor

  desc "add_location_tags", "tag users with checkin and todo location tags"
  def add_location_tags
    puts "#{Time.now}: adding location tags to users"

    require File.expand_path('config/environment.rb')

    User.all.each do |u|
      begin
        puts "#{Time.now}: [#{u.id}:#{u.handle}] adding tags"
        u.checkin_todo_locations.each do |l|
          u.event_location_tagged(l)
        end
      rescue Exception => e
        puts "#{Time.now}: #{e.message}"
      end
    end

    puts "#{Time.now}: completed"
  end
end