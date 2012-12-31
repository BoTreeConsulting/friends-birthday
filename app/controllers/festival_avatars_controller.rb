class FestivalAvatarsController < ApplicationController
  def index
    @festival_avatars = FestivalAvatar.all
  end

  def new
    @festival_avatar  = FestivalAvatar.new

  end

  def create
    festival_avatar = FestivalAvatar.new(params[:festival_avatar])
    if festival_avatar.save
      redirect_to "/festival_avatars/new"
    else
      render :action => 'new'
    end
  end

  def edit
  end

end
