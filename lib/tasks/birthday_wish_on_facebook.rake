namespace :viinfo  do
  require 'koala'
  desc "Post a wishing message at friend's facebook wall who has birthday today."
  task :birthday_wish_on_facebook => :environment do
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
      puts "Employee Email who is wishing birthday #{user.email}"
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
          custom_message = CustomMessage.find_by_friend_uid(birthday_person["id"])
          if custom_message.nil? || custom_message.blank?
            @message = "Wishing you a very special Happy Birthday..!!!!"
          else
            @message = custom_message.message
          end
          #@graph.put_wall_post("Happy Birthday..!!!!",birthday_person["id"])
          begin
            @graph.put_object(birthday_person["id"], "feed", :message => "#{@message}")
            puts "Posted on wall successfully"
          rescue Exception => e
            puts "==================================Facebook api graph error: #{e.message}"
          end
        end
      end
    end
  rescue Exception => e
    puts "===========================================>Error Message: #{e}"
  end
end

