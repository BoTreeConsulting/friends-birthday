class HomeController < ApplicationController
  def index
    @custom_message = CustomMessage.new
    begin
      if current_user.present?
        if current_user.fb_authentication.present?
          current_month, token, uid = initialise_objects()

          get_fb_graph_api_object(token)

          get_my_fb_profile(uid)
          get_fb_friends_profile(uid)
          #render :text => @me.inspect and return false

          @today_birthday = []
          get_todays_and_next_birthdays(current_month)
        end
      end
    rescue Exception => e
      flash[:notice]  = "Something went wrong.. Please check your internet connection."
      Rails.logger.info("================================> #{e.message}")
    end
  end

  def get_fb_friends_profile(uid)
    begin
      @friends_profile = @graph.get_connections("#{uid}", "friends", "fields" => "name,birthday,gender,link")
    rescue Exception => e
      Rails.logger.info("======================================> Error while getting friends profile: #{e.message}")
    end
  end

  def get_my_fb_profile(uid)
    begin
      @me = @graph.get_object("#{uid}","fields" => "likes,hometown,relationship_status,birthday,education,location,gender,")
    rescue Exception => e
      Rails.logger.info("=============================>Error while fetching My facebook profile : #{e.message}")
    end
  end

  def get_fb_graph_api_object(token)
    begin
      @graph = Koala::Facebook::API.new("#{token}")
    rescue Exception => e
      Rails.logger.info("=======================================> Error while initialise graph object: #{e.message} ")
    end
  end

  def initialise_objects
    @current_date = DateTime.now.new_offset(5.5/24).strftime('%m-%d-%Y').split('-')
    current_month = DateTime.now.new_offset(5.5/24).strftime('%B')
    @total_days = (Date.new(Time.now.year, 12, 31).to_date<<(12-(DateTime.now.strftime('%m')).to_i)).day
    @upcoming = @current_date[1].to_i+10
    @first_upcoming_birthday = []
    @nxt_upcoming_birthday = []
    @next_month_bday = []
    uid = current_user.fb_authentication.uid
    token = current_user.fb_authentication.token
    return current_month, token, uid
  end

  def get_todays_and_next_birthdays(current_month)
    @friends_profile.each do |friend|
      if !friend["birthday"].nil?
        birthday = friend["birthday"].split('/')
        if @current_date[0] == birthday[0]
          #month is same
          if @current_date[1]==birthday[1]
            #Date is same
            #@today_birthday << friend["id"]
            @today_birthday << {"name" => friend["name"], "birthday" => "#{birthday[1]}"+" #{current_month}", "id" => friend["id"], "link" => friend["link"], "gender" => friend["gender"]}
          end
          if birthday[1].to_i > @current_date[1].to_i && birthday[1].to_i < @upcoming
            @first_upcoming_birthday << {"name" => friend["name"], "birthMonth" => birthday[0], "birthDate" => birthday[1], "birthday" => birthday[1]+" #{current_month}", "id" => friend["id"], "link" => friend["link"], "flag" => 1, "gender" => friend["gender"]}
          end

        elsif birthday[0].to_i == @current_date[0].to_i+1
          if birthday[1].to_i >=1 && birthday[1].to_i < (@upcoming-@total_days.to_i)
            @nxt_upcoming_birthday << {"name" => friend["name"], "birthMonth" => birthday[0], "birthDate" => birthday[1], "birthday" => birthday[1]+" #{(DateTime.now + 1.month).new_offset(5.5/24).strftime('%B')}", "id" => friend["id"], "link" => friend["link"], "gender" => friend["gender"]}
          end
          @next_month_bday << {"name" => friend["name"], "birthday" => birthday[1], "id" => friend["id"]}
        end
        if !@nxt_upcoming_birthday.blank?
          @nxt_upcoming_birthdays = @nxt_upcoming_birthday.sort_by { |hsh| hsh["birthday"] }
          @nxt_upcoming_birthdays = @first_upcoming_birthday+@nxt_upcoming_birthday
        else
          @nxt_upcoming_birthdays = @first_upcoming_birthday.sort_by { |hsh| hsh["birthday"] } if @first_upcoming_birthday.present?
        end
      end
    end
  end
end
