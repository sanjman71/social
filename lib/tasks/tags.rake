namespace :tags do

  desc "Build tag badges"
  task :add_badges => :environment do
    puts "#{Time.now}: adding user tag badges"
    istart = TagBadging.count
    User.all.each do |user|
      user.add_tag_badges
    end
    iend = TagBadging.count
    puts "#{Time.now}: added #{iend-istart} user tag badges"
  end
  
end