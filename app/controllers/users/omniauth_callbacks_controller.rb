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
    user = User.find_by_email(@email)
    if user.present?
      user
      fb_authentication = FbAuthentication.find_by_user_id(user.id)
      if fb_authentication.present?
        fb_authentication.update_attribute('token',request.env["omniauth.auth"].credentials.token)
      end
    else # Create a user with a stub password.
      user = User.new
      user.email = @email
      user.encrypted_password = Devise.friendly_token[0,20]
      user.save(:validate => false)
      auth = FbAuthentication.find_by_uid_and_user_id(data.uid,@email)
      if auth.nil?
        fb_authentication = FbAuthentication.new
        fb_authentication.uid = request.env["omniauth.auth"].uid
        fb_authentication.token = request.env["omniauth.auth"].credentials.token
        fb_authentication.user_id = @user.id
        fb_authentication.save
      end
    end

      if user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "#{params[:action]}".capitalize
      sign_in_and_redirect user, :event => :authentication
    else
      session["devise.#{params[:action]}_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end

  end




end
