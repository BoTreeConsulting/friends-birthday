namespace :new_year  do
  require 'koala'
  desc "Post a 2013 welcome wishing message at friend's facebook wall."
  task :wish_on_facebook => :environment do
    users  = User.all(:joins =>:fb_authentication)
    if users.present?
      wishing_at_facebook_wall(users)
    end
  end
end

def wishing_at_facebook_wall(users)
  begin
    users.each do |user|
      @graph = Koala::Facebook::API.new("#{user.fb_authentication.token}")
      @friends_profile = @graph.get_connections(user.fb_authentication.uid, "friends", "fields"=>"name")
      puts "Person Email who is wishing new year #{user.email}"
       i = 0
      @friends_profile.each do |friend|
        if i = 0
          puts friend["name"]
          restricted_friends_uids_arr = RestrictedFriend.where(:user_id => user.id).pluck(:uid)
          flag = true
          if restricted_friends_uids_arr.present?
            if restricted_friends_uids_arr.include?(friend["id"])
              flag = false
            end
          end
          if flag
            @message = "Happy New year.. :)..!!!!"
            image_link = FestivalAvatar.find((1..12).to_a.sample).avatar.url
            begin
              @graph.put_picture("#{(Rails.root).join("public"+image_link)}", { "message" => "#{@message}" }, friend["id"])
             # @graph.put_object(friend["id"], "feed", :message => "#{@message}")

              puts "Posted on wall successfully"
              break
            rescue Exception => e
              puts "==================================Facebook api graph error: #{e.message}"
            end
          else
            puts "====================================> #{friend["name"]} has been restricted to wish via FriendsBirthday apps. "
          end
        end

      end
    end
  rescue Exception => e
    puts "===========================================>Error Message: #{e}"
  end
end

