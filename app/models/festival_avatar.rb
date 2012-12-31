class FestivalAvatar < ActiveRecord::Base

  require 'carrierwave/orm/activerecord'

  attr_accessible :avatar, :event_id

  mount_uploader :avatar, AvatarUploader

  has_many :events
end
