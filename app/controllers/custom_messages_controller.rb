class CustomMessagesController < ApplicationController
  # GET /custom_messages
  # GET /custom_messages.json
  def index
    @custom_messages = CustomMessage.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @custom_messages }
    end
  end

  # GET /custom_messages/1
  # GET /custom_messages/1.json
  def show
    @custom_message = CustomMessage.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @custom_message }
    end
  end

  # GET /custom_messages/new
  # GET /custom_messages/new.json
  def new
    @custom_message = CustomMessage.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @custom_message }
    end
  end

  # GET /custom_messages/1/edit
  def edit
    @custom_message = CustomMessage.find(params[:id])
  end

  # POST /custom_messages
  # POST /custom_messages.json
  def create
    current_id = current_user.id
    token = current_user.fb_authentication.token
    get_graph_api_object(token)
    @friend_uid = params[:custom_message]["friend_uid"]
    birthday_avatar_disable = BirthdayAvatarDisable.find_by_user_id_and_friend_uid(current_id,@friend_uid)
    if birthday_avatar_disable
      if params["addGreeting"] == "yes"
        birthday_avatar_disable.destroy
        @greeting_disabled = false
      else
        @greeting_disabled = true
      end
    else
      if params["addGreeting"] == "no"
        BirthdayAvatarDisable.create(:user_id => current_id,:friend_uid => @friend_uid,:disabled => 0)
        @greeting_disabled = true
      else
        @greeting_disabled = false
      end
    end

    @friend_name  = params["friend_name"]
    no_message_available = CustomMessage.find_by_friend_uid_and_user_id(params[:custom_message]["friend_uid"],current_id).nil?
    unless params[:is_birthday_today] == "true"
      if no_message_available
        params[:custom_message][:message]  = params[:custom_message][:message].lstrip
        custom_message = CustomMessage.new(params[:custom_message])
        unless custom_message.blank?
          custom_message.user_id = current_user.id
          if custom_message.save
            @custom_message = custom_message
            @custom_message_create = true
            flash[:notice] = "Your message has been added successfully"
          end
        else
          flash[:alert] = "Please write something. Blank message will not be allow."
        end
      else
        @custom_message = CustomMessage.find_by_friend_uid_and_user_id(@friend_uid,current_id)
        if @custom_message.update_attributes(params[:custom_message])
          @custom_message_create = false

          flash[:notice] = "Your message has been updated successfully"
        else
          flash[:error] = "We are sorry, please update again."
        end
      end
    else
      begin
        restricted_friends_uids_arr = RestrictedFriend.where(:user_id =>current_id).pluck(:uid)
        disabled_avatar_friends_uids_arr = BirthdayAvatarDisable.where(:user_id => current_user.id).pluck(:friend_uid)

        flag = true
        if restricted_friends_uids_arr.present?
          if restricted_friends_uids_arr.include?(@friend_uid)
            flag = false
          end
        end
        if flag
          unless params[:custom_message][:message].blank?
            image_link = BirthdayAvatar.find((1..49).to_a.sample).avatar.url
            if disabled_avatar_friends_uids_arr.present?
              if disabled_avatar_friends_uids_arr.include?(@friend_uid)
                begin
                  @graph.put_object(@friend_uid, "feed", :message => "#{params[:custom_message][:message]}")
                rescue Exception => e
                  puts "============================> Error while sending Greeting: #{e.message}"
                end
              else
                begin
                  @graph.put_picture("#{(Rails.root).join("public"+image_link)}", { "message" => "#{params[:custom_message][:message]}" }, @friend_uid)
                rescue Exception => e
                  puts "============================> Error while posting on wall: #{e.message}"
                end
              end
            end

            flash[:notice] = "Message posted at facebook wall"
            puts "==================================Successfully updated wall"
          else

          end
        end
      rescue Exception => e
        puts "==================================Facebook api graph error: #{e.message}"
      end
    end
    respond_to do |format|
      format.js
    end
  end

  def get_graph_api_object(token)
    @graph = Koala::Facebook::API.new("#{token}")
  end

  # PUT /custom_messages/1
  # PUT /custom_messages/1.json
  def update
    @custom_message = CustomMessage.find_by_friend_uid(params[:custom_message]["friend_uid"])

    respond_to do |format|
      if @custom_message.update_attributes(params[:custom_message])
        format.html { redirect_to @custom_message, notice: 'Custom message has been updated successfully .' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @custom_message.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /custom_messages/1
  # DELETE /custom_messages/1.json
  def destroy
    @custom_message = CustomMessage.find(params[:id])
    @custom_message.destroy
    @friend_uid = @custom_message.friend_uid
    respond_to do |format|
      format.js
    end
  end

end
