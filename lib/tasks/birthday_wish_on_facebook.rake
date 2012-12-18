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
      @graph = Koala::Facebook::API.new("#{user.fb_authentication.token}")
      @friends_profile = @graph.get_connections(user.fb_authentication.uid, "friends", "fields"=>"name,birthday,gender,link")
      me = @graph.get_object("#{user.fb_authentication.uid}")
      puts "I m #{me["first_name"]} who is wishing my friend's birthday."
      puts me.inspect
      puts "Person Email who is wishing birthday #{user.email}"
      @friends_profile.each do |friend|
        if !friend["birthday"].nil?
          birthday = friend["birthday"].split('/')
          if @current_date[0] == birthday[0]
            #month is same
            if @current_date[1]==birthday[1]
              #Date is same
              #@today_birthday << friend["id"]
              @today_birthday <<  {"name" => friend["name"],"birthday" => "#{birthday[1]}"+" #{current_month}","id" => friend["id"],"link" => friend["link"]}
            end
          end
        end
      end
      puts @today_birthday
      unless @today_birthday.blank?
        @today_birthday.each do |birthday_person|
          restricted_friends_uids_arr = RestrictedFriend.where(:user_id => user.id).pluck(:uid)
          flag = true
          if restricted_friends_uids_arr.present?
            if restricted_friends_uids_arr.include?(birthday_person["id"])
              flag = false
            end
          end
          if flag
            custom_message = CustomMessage.find_by_friend_uid(birthday_person["id"])
            if custom_message.nil? || custom_message.blank?
              @message = "Wishing you a very special Happy Birthday..!!!!"
            else
              @message = custom_message.message
            end
            image_link = BirthdayAvatar.find((1..49).to_a.sample).avatar.url

            begin
              @graph.put_picture("#{(Rails.root).join("public"+image_link)}", { "message" => "#{@message}" }, birthday_person["id"])
              #@graph.put_object(birthday_person["id"], "feed", :message => "#{@message}")
              puts "Posted on wall successfully"
            rescue Exception => e
              puts "==================================Facebook api graph error: #{e.message}"
            end
          else
            puts "====================================> #{birthday_person["name"]} has been restricted to wish via FriendsBirthday apps. "
          end
        end
      else
        puts "============================> #{me["first_name"]}, Today you have no friends who have birthday"
      end
    end
  rescue Exception => e
    puts "===========================================>Error Message: #{e}"
  end
end

