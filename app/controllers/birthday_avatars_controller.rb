class BirthdayAvatarsController < ApplicationController
  def index
    @birthday_avatars = BirthdayAvatar.all
  end

  def new
    @birthday_avatar  = BirthdayAvatar.new

  end

  def create
    @birthday_avatar = BirthdayAvatar.new(params[:birthday_avatar])
    if @birthday_avatar.save
      redirect_to "/birthday_avatars/new"
    else
      render :action => 'new'
    end
  end

  def edit
  end
end
