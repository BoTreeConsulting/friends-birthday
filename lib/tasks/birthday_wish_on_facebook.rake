namespace :friends_birthday  do
  require 'koala'
  desc "Post a wishing message at friend's facebook wall who has birthday today."
  task :wish_on_facebook => :environment do
  users  = User.all(:joins =>:fb_authentication)
    if users.present?
      wishing_at_facebook_wall(users)
    end
  end
end



def wishing_at_facebook_wall(users)
  begin
    @current_date = DateTime.now.new_offset(5.5/24).strftime('%m-%d-%Y').split('-')
    current_month = DateTime.now.new_offset(5.5/24).strftime('%b')
    puts "Current Date: #{@current_date}"
    users.each do |user|
      @today_birthday = []
      skip = get_graph_object(user)
      unless skip
        begin
          fb_user = @graph.get_object("#{user.fb_authentication.uid}")
          @friends_profile = @graph.get_connections(user.fb_authentication.uid, "friends", "fields"=>"name,birthday,gender,link")
          get_today_birthdays_collections(current_month)
          unless @today_birthday.blank?
            set_messages_for_teminal(fb_user, user)
            restricted_friends_uids_arr = RestrictedFriend.where(:user_id => user.id).pluck(:uid)
            disabled_avatar_friends_uids_arr = BirthdayAvatarDisable.where(:user_id => user.id).pluck(:friend_uid)

            @today_birthday.each do |birthday_person|
              flag = get_restricted_friends(birthday_person, restricted_friends_uids_arr)
              unless flag
                get_birthday_message(birthday_person)

                image_link = BirthdayAvatar.find((1..49).to_a.sample).avatar.url

                begin
                  post_at_wall(birthday_person, disabled_avatar_friends_uids_arr, image_link)
                rescue Exception => e
                  puts "==================>(line:42) Facebook Graph-Api Error: #{e.message}"
                end
              else
                puts "==================>(line:45) #{fb_user["first_name"]} has restricted #{birthday_person["name"]} to wish via FriendsBirthday App. "
              end
            end
          else
            puts "==================>(line:49) #{fb_user["first_name"]}, Today you have no friends who have birthday"
          end
        rescue Exception => e
          #user.destroy
          puts "==================>(line:53) #{e.message}"
        end
      end
    end
  rescue Exception => e
    puts "==================>(line:58) Error Message: #{e.message}"
  end
end

def get_graph_object(user)
  skip = false
  begin
    @graph = Koala::Facebook::API.new("#{user.fb_authentication.token}")
  rescue Exception => e
    puts "==================>(line:67) Graph API object error: #{e.message}"
    skip = true
  end
  skip
end

def get_today_birthdays_collections(current_month)
  @friends_profile.each do |friend|
    if !friend["birthday"].nil?
      birthday = friend["birthday"].split('/')
      if @current_date[0] == birthday[0]
        #month is same
        if @current_date[1]==birthday[1]
          #Date is same
          #@today_birthday << friend["id"]
          @today_birthday << {"name" => friend["name"], "birthday" => "#{birthday[1]}"+" #{current_month}", "id" => friend["id"], "link" => friend["link"]}
        end
      end
    end
  end
end

def set_messages_for_teminal(fb_user, user)
  puts "==================> Today's Birthday Collection"
  puts "##################################################################"
  puts "User's FB Name who is wishing: #{fb_user["first_name"]}"
  puts "User's Email who is wishing: #{user.email}"
  puts "##################################################################"
  puts "#{@today_birthday}"
  puts "================================================"
end

def get_restricted_friends(birthday_person, restricted_friends_uids_arr)
  flag = false
  if restricted_friends_uids_arr.present?
    if restricted_friends_uids_arr.include?(birthday_person["id"])
      flag = true
    end
  end
  flag
end

def get_birthday_message(birthday_person)
  custom_message = CustomMessage.find_by_friend_uid(birthday_person["id"])
  if custom_message.nil? || custom_message.blank?
    @message = "Happy Birthday...."
  else
    @message = custom_message.message
    custom_message.destroy
  end
end

def post_at_wall(birthday_person, disabled_avatar_friends_uids_arr, image_link)
  begin
    if disabled_avatar_friends_uids_arr.present?
      if disabled_avatar_friends_uids_arr.include?(birthday_person["id"])
        @graph.put_object(birthday_person["id"], "feed", :message => "#{@message}")
        puts "==================>(line:124) Simple message has been posted successfully on #{birthday_person["name"]}'s wall"
      else
        @graph.put_picture("#{(Rails.root).join("public"+image_link)}", {"message" => "#{@message}"}, birthday_person["id"])
        puts "==================>(line:127) Greeting with message has been posted successfully on #{birthday_person["name"]}'s wall"
      end
    else
      @graph.put_picture("#{(Rails.root).join("public"+image_link)}", {"message" => "#{@message}"}, birthday_person["id"])
      puts "==================>(line:131) Greeting with message has been posted successfully on #{birthday_person["name"]}'s wall"
    end
  rescue Exception => e
    puts "==================>(line:134) Not posted at wall #{e.message}"
    puts "==================>(line:135) Trying to send simple message"
    begin
      @graph.put_object(birthday_person["id"], "feed", :message => "#{@message}")
      puts "==================>(line:138) Simple message has been posted successfully on #{birthday_person["name"]}'s wall"
    rescue Exception => e
      puts "==================>(line:140) Not able to send even simple message"
      puts "==================>(line:141) #{e.message}"
    end
  end
end
