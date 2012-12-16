class RestrictedFriendsController < ApplicationController
  # GET /restricted_friends
  # GET /restricted_friends.json
  def index
    get_friends_profile()
    @restricted_friends = RestrictedFriend.where(:user_id => current_user.id)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @restricted_friends }
    end
  end

  # GET /restricted_friends/1
  # GET /restricted_friends/1.json
  def show
    @restricted_friend = RestrictedFriend.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @restricted_friend }
    end
  end

  # GET /restricted_friends/new
  # GET /restricted_friends/new.json
  def new
    @restricted_friend = RestrictedFriend.new
    get_friends_profile()
    @restricted_friends = RestrictedFriend.where(:user_id => current_user.id).pluck(:uid)
    #render :text => @restricted_friends.inspect and return false
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @restricted_friend }
    end
  end

  def get_friends_profile
    fb_authentication = current_user.fb_authentication
    if fb_authentication.present?
      token = fb_authentication.token
      uid = fb_authentication.uid
      @graph = Koala::Facebook::API.new("#{token}")
      @friends_profile = @graph.get_connections("#{uid}", "friends", "fields" => "name,picture,gender", "offset" => 0, "limit" => 500000)
    end
  end

  # GET /restricted_friends/1/edit
  def edit
    @restricted_friend = RestrictedFriend.find(params[:id])
  end

  # POST /restricted_friends
  # POST /restricted_friends.json
  def create
    get_friends_profile()
    restricted_friends = RestrictedFriend.where(:user_id => current_user.id)
    if restricted_friends.present?
      restricted_friends.each do |restricted_friend|
        restricted_friend.destroy
      end
    end
    if params["restricted_friend"].present? && params["restricted_friend"]["uid"].present?
      params["restricted_friend"]["uid"].each do |friend_id|
        avail = RestrictedFriend.find_by_uid_and_user_id(friend_id,current_user.id)
        if avail.nil?
          RestrictedFriend.create(:uid => friend_id,:user_id => current_user.id)
        end
      end
    end
    redirect_to "/restricted_friends/new"
  end

  # PUT /restricted_friends/1
  # PUT /restricted_friends/1.json
  def update
    @restricted_friend = RestrictedFriend.find(params[:id])

    respond_to do |format|
      if @restricted_friend.update_attributes(params[:restricted_friend])
        format.html { redirect_to @restricted_friend, notice: 'Restricted friend was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @restricted_friend.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /restricted_friends/1
  # DELETE /restricted_friends/1.json
  def destroy
    @restricted_friend = RestrictedFriend.find(params[:id])
    @restricted_friend.destroy

    respond_to do |format|
      format.html { redirect_to restricted_friends_url }
      format.json { head :no_content }
    end
  end
end
