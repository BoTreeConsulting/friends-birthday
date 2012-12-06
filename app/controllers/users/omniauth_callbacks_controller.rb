class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
	#require 'koala'
  def facebook
		data = request.env["omniauth.auth"].extra.raw_info
    session[:access_token] = request.env["omniauth.auth"].credentials.token
		if data.email.nil?
				@email = data.link
		else
			@email = data.email
		end
    @auth = FbAuthentication.find_by_uid_and_user_id(data.uid,@email)

    if @auth.nil?
      fb_authentication = FbAuthentication.new
      fb_authentication.uid = request.env["omniauth.auth"].uid
      fb_authentication.token = request.env["omniauth.auth"].credentials.token
      fb_authentication.user_id = current_user.id
      fb_authentication.save
	end
    redirect_to root_url
  end


end
