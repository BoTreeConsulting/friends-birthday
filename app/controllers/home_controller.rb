class HomeController < ApplicationController
  require 'gchart'

  def index
    @custom_message = CustomMessage.new
    @user = User.find(1)
    #@user.fb_profile  << 10
    #render :text => @user.fb_profile.clear  and return false
    if current_user.present?
      if current_user.fb_authentication.present?

        current_month, token, uid = initialise_objects()
        begin
          get_fb_graph_api_object(token)
        rescue Exception => e
          Rails.logger.info("=================================>Error at Graph Api object initialization: #{e.message}")
        end

        begin
          get_my_fb_profile(uid,"")
        rescue Exception => e
          Rails.logger.info("===================================> Error while getting user profile details: #{e.message}")
        end

        begin
          get_fb_friends_profile(uid)
        rescue Exception => e
          Rails.logger.info("====================================> Error while getting user friends profile details: #{e.message}")
        end

        begin
          get_today_and_next_birthdays(current_month)
        rescue Exception => e
          Rails.logger.info("========================================> Error while getting user's friends today and upcoming birthday #{e.message}")
        end

        begin

        rescue

        end
      end
    end
  end

  def get_total_tagged_pictures(uid)
    user_picture_details = @graph.get_connections(uid, "?fields=photos.limit(100000)")
    @total_user_tagged_picture = user_picture_details["photos"].present? ? user_picture_details["photos"]["data"].size : 0
  end


  def analysis
    if current_user.present?
      fb_authentication = current_user.fb_authentication
      if fb_authentication.present?

        token = fb_authentication.token
        uid =   fb_authentication.uid

        # it should be store in redis server.
        #
        get_fb_graph_api_object(token)
        @user_default_profile = get_my_fb_profile(uid,"")
        #
        #
        #get_total_tagged_pictures(uid)
        calculate_user_present_age_and_upcoming_birthday()
        get_large_user_profile_image(uid)
        get_user_statues_details(uid)
        friends_locations = get_friends_country_location(uid)
        calculate_count_of_the_friends_with_same_country(friends_locations)
        location_map_data()
        get_user_album_with_most_likes_and_comments(uid)
        get_most_liked_and_commented_status()

        get_user_groups(uid)
        get_fb_friends_profile(uid)
        initialize_objects_for_relationship_status()
        #initialize_location_objects()

        @friends_profile.each do |friend|
          calculate_total_male_female_friends(friend)
          calculate_friends_relationship_status(friend)
          #analyse_friends_location(friend)
        end
      else
        flash[:notice] = "Please Connect with facebook Apps"
        redirect_to root_url
      end
    end
  end

  def get_large_user_profile_image(uid)
    @user_profile_image = @graph.get_picture(uid, :type => "large")
  end

  def location_map_data
    @friends_country = [['Country', 'Friends']]
    @friends_location_analysis.delete("country_not_defined")
    @friends_location_analysis.each do |country_name, count|
      arr = []
      arr << country_name
      arr << count
      @friends_country << arr
    end
  end

  def calculate_count_of_the_friends_with_same_country(friends_locations)
    @friends_location_analysis = {}
    @total_friends_country_count = 0
    @friends_location_analysis["country_not_defined"] = 0
    if friends_locations.present?
      friends_locations.each do |friend_location|
        if friend_location["current_location"].present?
          country_name = friend_location["current_location"]["country"]
          if @friends_location_analysis.has_key?(country_name)
            @friends_location_analysis[country_name] = @friends_location_analysis[country_name].to_i + 1
          else
            @friends_location_analysis[country_name] = 1
          end
          @total_friends_country_count = @total_friends_country_count + 1
        else
          @friends_location_analysis["country_not_defined"] = @friends_location_analysis["country_not_defined"].to_i + 1
        end
      end
    end
  end

  def get_friends_country_location(uid)
    friends_locations = @graph.fql_query("SELECT current_location.state,current_location.country FROM user WHERE uid in (SELECT uid2 FROM friend where uid1 = #{uid} ) LIMIT 100000")
  end

  def get_user_statues_details(uid)
    @user_statuses_details = get_my_fb_extra_details(uid, "statuses")
    @total_user_statuses_count = @user_statuses_details["statuses"].present? ? @user_statuses_details["statuses"]["data"].size : 0
  end

  def get_user_album_with_most_likes_and_comments(uid)
    user_albums_details = @graph.get_connections(uid, "?fields=albums.limit(100000).fields(name,likes.limit(10000000),count,comments.limit(1000000),cover_photo,type)")


    @total_user_albums_count = user_albums_details["albums"]["data"].size
    if user_albums_details["albums"]["data"].present?
      @user_albums = []
      user_albums_details["albums"]["data"].each do |album|
        user_album = {}

        user_album["likes_count"] = album["likes"].present? ? album["likes"]["data"].size : 0
        user_album["comments_count"] = album["comments"].present? ? album["comments"]["data"].size : 0
        user_album["name"] = album["name"]
        user_album["cover_photo"] = album["cover_photo"]

        @user_albums << user_album
      end
      user_most_liked_albums = @user_albums.sort_by { |hsh| hsh["likes_count"] }
      @user_most_liked_album = user_most_liked_albums.reverse[0]
      user_most_commented_albums = @user_albums.sort_by { |hsh| hsh["comments_count"] }
      @user_most_commented_album = user_most_commented_albums.reverse[0]
    end
  end

  def user_next_page_data(page,last_value)
    if page.next_page.present?
      last_value = last_value + page.next_page.size
      page = page.next_page
      if page.next_page.present?
        user_next_page_data(page,last_value)
      end
    end
    return last_value
  end

  def initialize_location_objects
    @friends_location = {}
    @friends_location["no_location"] = {}
    @friends_location["no_location"]["count"] = 0
    @friends_location["no_location"]["picture_urls"] = []
    @friends_location["no_location"]["location_name"] = "Location Not Defined"
  end

  def get_user_groups(uid)
    begin
      @user_groups_details = @graph.get_connections("#{uid}", "groups", :fields => "name,owner,description")
    rescue Exception => e
      Rails.logger.info("=============================> Error At Line:40 #{e.message}")
    end
  end

  def get_most_liked_and_commented_status
    if @user_statuses_details.present? && @user_statuses_details["statuses"].present?
      @user_statues = []
      group_status_count = {}
      @total_status_comments = 0
      @total_status_likes = 0
      @user_statuses_details["statuses"]["data"].each do |status|
        month_status_hsh_ky = Time.parse(status["updated_time"]).strftime("%m-%Y")
        s = (status["comments"].present?) ? status["comments"]["data"].size : 0
        l = (status["likes"].present?) ? status["likes"]["data"].size : 0
        if group_status_count.has_key?("#{month_status_hsh_ky}")
          group_status_count["#{month_status_hsh_ky}"]["count"] = group_status_count["#{month_status_hsh_ky}"]["count"].to_i + 1
          group_status_count["#{month_status_hsh_ky}"]["comments"] = group_status_count["#{month_status_hsh_ky}"]["comments"].to_i + s
          group_status_count["#{month_status_hsh_ky}"]["likes"] = group_status_count["#{month_status_hsh_ky}"]["likes"].to_i + l
          puts "===============================If=============> #{group_status_count}"
        else
          group_status_count["#{month_status_hsh_ky}"] = {"count" => 1,"comments" => s,"likes" => l}
          puts "=======================else======>#{group_status_count} "
        end

        @user_status_chart_data = [["Months","Statues","comments","likes"]]
        if group_status_count.present?
          reversed_group_status_count = Hash[group_status_count.to_a.reverse]
          status_chart_data_count = 0
          reversed_group_status_count .each do |grouped_status,v|
            if status_chart_data_count < 6
              arr = []
              arr << grouped_status
              arr << v["count"]
              arr << v["comments"]
              arr << v["likes"]
              @user_status_chart_data << arr
              status_chart_data_count = status_chart_data_count + 1
            end
          end
        end
        #puts "Time Time Time Time Time Time Time ================================>#{month_status_hsh_ky} : #{status["message"]}"
        puts "#{@user_status_chart_data} ================================>#Test new"
        user_status = {}
        user_status["message"] = status["message"]
        s = (status["comments"].present?) ? status["comments"]["data"].size : 0
        user_status["comments_count"] = s

        @total_status_comments = @total_status_comments + s
        l = (status["likes"].present?) ? status["likes"]["data"].size : 0
        user_status["likes_count"] = l
        @total_status_likes = @total_status_likes + l
        unless user_status.blank?
          @user_statues << user_status
        end
      end
      puts "==============================>Total Comments: #{@total_status_comments} "
      puts "==============================>Total Likes: #{@total_status_likes}"
      user_most_commented_status = @user_statues.sort_by { |hsh| hsh["comments_count"] }
      @user_most_commented_status = user_most_commented_status.reverse[0..4]
      user_most_liked_status = @user_statues.sort_by { |hsh| hsh["likes_count"] }
      @user_most_liked_status = user_most_liked_status.reverse[0..4]
    end
  end

  #def analyse_friends_location(friend)
  #
  #  unless friend["location"].nil?
  #    if @friends_location.has_key?(friend["location"]["id"])
  #      @friends_location[friend["location"]["id"]]["count"] = @friends_location[friend["location"]["id"]]["count"] + 1
  #      @friends_location[friend["location"]["id"]]["location_name"] = friend["location"]["name"]
  #      @friends_location[friend["location"]["id"]]["picture_urls"] << friend["picture"]["data"]["url"]
  #    else
  #      @friends_location[friend["location"]["id"]] = {}
  #      @friends_location[friend["location"]["id"]]["picture_urls"] = []
  #      @friends_location[friend["location"]["id"]]["count"] = 1
  #      @friends_location[friend["location"]["id"]]["location_name"] = friend["location"]["name"]
  #      @friends_location[friend["location"]["id"]]["picture_urls"] << friend["picture"]["data"]["url"]
  #    end
  #  else
  #    @friends_location["no_location"]["count"] = @friends_location["no_location"]["count"] + 1
  #    @friends_location["no_location"]["picture_urls"] << friend["picture"]["data"]["url"]
  #  end
  #end

  def calculate_friends_relationship_status(friend)
    unless friend["relationship_status"].nil?
      case friend["relationship_status"]
        when "Married"
          @married_count = @married_count + 1
        when "Single"
          @single_count = @single_count + 1
        when "It's complicated"
          @its_complicated_count = @its_complicated_count + 1
        when "In a relationship"
          @relationship_count = @relationship_count + 1
        when "In an open relationship"
          @open_relationship_count = @open_relationship_count + 1
        when "Engaged"
          @engaged_count = @engaged_count + 1
      else
        @other_count = @other_count + 1
      end
    else
      @other_count = @other_count + 1
    end

    @arr = [@married_count,@single_count,@relationship_count,@open_relationship_count,@engaged_count,@other_count].sort
    @max_count = @arr[-1]
  end

  def initialize_objects_for_relationship_status
    @male_count = 0
    @female_count = 0
    @gender_not_defined = 0
    @married_count = 0
    @single_count = 0
    @its_complicated_count = 0
    @other_count = 0
    @not_defined = 0
    @open_relationship_count = 0
    @engaged_count = 0
    @relationship_count = 0
  end

  def calculate_total_male_female_friends(friend)
    unless friend["gender"].nil?
      case friend["gender"]
        when "male"
          @male_count = @male_count+1
        when "female"
          @female_count = @female_count + 1
        else
          @gender_not_defined = @gender_not_defined + 1
      end
      data = [10,100,300]
      @ratio_img_male_female = Gchart.pie_3d(data: data, size: '300x200', bar_colors: '1277bd,519bcf,90c0e0,b0d2e9,ffdfaf,ffc875,ffb03a,7C0808', bg_color: 'fff')
    end
  end

  def calculate_user_present_age_and_upcoming_birthday
    unless @user_default_profile["birthday"].nil?
      user_birthday = @user_default_profile["birthday"].gsub('/', '-')
      unless user_birthday.nil?
        get_user_age(user_birthday)
      end
      next_birthdate_diff = get_user_next_birthday_detail(user_birthday)
      if next_birthdate_diff.present?
        @next_birthday = []
        @next_birthday << "#{next_birthdate_diff[:month]} months" unless next_birthdate_diff[:month] == 0
        @next_birthday << "#{next_birthdate_diff[:days]} days" if next_birthdate_diff[:days].present?
      end
      @next_birthday = @next_birthday.join(" ")
    end
  end

  def get_user_next_birthday_detail(user_birthday)
    birthdate = user_birthday.split('-')
    next_birthday_date = birthdate[1]+'-'+birthdate[0]+'-'+(DateTime.now + 1.year).year.to_s
    Time.diff(Time.now, Time.parse(next_birthday_date))
  end

  def get_user_age(birthday)
    birthday = birthday.split('-')
    if birthday.size == 3
      birthdate = birthday[1]+'-'+birthday[0]+'-'+birthday[2]
      pars_date = birthdate
      @user_birthday = Time.parse(pars_date).strftime('%A, %B %e %Y')
      @user_total_age = Time.diff(Time.parse(birthdate), Time.now)
      @user_current_age = []
      @user_current_age << "#{@user_total_age[:year]} years" unless @user_total_age[:year] == 0
      @user_current_age << " old"
      @user_current_age = @user_current_age.join(" ")
    end
  end



  def destroy_fb_authentication
    fb_authentication = FbAuthentication.find(current_user.fb_authentication.id)
    fb_authentication.destroy
    redirect_to root_path
  end

  def get_fb_graph_api_object(token)
    begin
      @graph = Koala::Facebook::API.new("#{token}")
    rescue Exception => e
      Rails.logger.info("=======================================> Error while initialise graph object: #{e.message} ")
    end
  end

  def get_my_fb_profile(uid,fields)
    begin
      @me = @graph.get_object("#{uid}","fields" => "#{fields}")
    rescue Exception => e
      Rails.logger.info("=============================>Error while fetching My facebook profile : #{e.message}")
    end
  end

  def get_my_fb_extra_details(uid,fields)
    begin

      @extra_details = @graph.get_connections("#{uid}","?fields=statuses.limit(100000).fields(comments.limit(1000000),message,likes.limit(1000000))")
    rescue Exception => e
      Rails.logger.info("=============================>Error while fetching My facebook profile : #{e.message}")
    end
  end

  def get_fb_friends_profile(uid)
    begin
      @friends_profile = @graph.get_connections("#{uid}", "friends", "fields" => "name,birthday,gender,link,relationship_status,location,picture","offset"=>0,"limit"=> 500000)
    rescue Exception => e
      Rails.logger.info("======================================> Error while getting friends profile: #{e.message}")
    end
  end



  def initialise_objects
    @current_date = DateTime.now.new_offset(5.5/24).strftime('%m-%d-%Y').split('-')
    current_month = DateTime.now.new_offset(5.5/24).strftime('%B')
    @total_days = (Date.new(Time.now.year, 12, 31).to_date<<(12-(DateTime.now.strftime('%m')).to_i)).day
    @upcoming = @current_date[1].to_i+10
    @upcoming_birthdays = []
    @next_month_birthday = []
    @today_birthday = []
    uid = current_user.fb_authentication.uid
    token = current_user.fb_authentication.token
    return current_month, token, uid
  end

  def get_today_and_next_birthdays(current_month)
    @friends_profile.each do |friend|
      if !friend["birthday"].nil?
        birthday = friend["birthday"].split('/')
        if @current_date[0] == birthday[0]
          #month is same
          if @current_date[1]==birthday[1]
            #Date is same
            @today_birthday << {"name" => friend["name"], "birthday" => "#{birthday[1]}"+" #{current_month}", "id" => friend["id"], "link" => friend["link"], "gender" => friend["gender"]}
          end
          if birthday[1].to_i > @current_date[1].to_i
            @upcoming_birthdays << {"name" => friend["name"], "birthMonth" => birthday[0], "birthDate" => birthday[1], "birthday" => birthday[1]+" #{current_month}", "id" => friend["id"], "link" => friend["link"], "flag" => 1, "gender" => friend["gender"]}
          end

        elsif birthday[0].to_i == DateTime.now.new_offset(5.5/24).next_month.strftime('%m').to_i
          @next_month_birthday << {"name" => friend["name"], "birthday" => birthday[1], "birthday" => birthday[1]+" #{(DateTime.now + 1.month).new_offset(5.5/24).strftime('%B')}", "id" => friend["id"], "link" => friend["link"], "gender" => friend["gender"]}
        end
        #Rails.logger.info("========================================================> #{@next_month_bday}")
      end
    end


    if @upcoming_birthdays.present?
      @upcoming_birthdays = @upcoming_birthdays.sort_by { |hsh| hsh["birthday"] }
      puts  "==========================>"
      puts  "==========================> upcoming birthday: #{@nxt_upcoming_birthdays} "
      puts  "==========================> upcoming birthday END"

    end

    if @next_month_birthday.present?
      @next_month_birthday = @next_month_birthday.sort_by { |hsh| hsh["birthday"] }
      @upcoming_birthdays = @upcoming_birthdays + @next_month_birthday
      puts  "==========================>"
      puts  "==========================> Next Month birthday: #{@upcoming_birthdays} "
      puts  "==========================> Next Month birthday END"


    end

  end
end
