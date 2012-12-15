class BirthdayAvatar < ActiveRecord::Base
  require 'carrierwave/orm/activerecord'
  attr_accessible :avatar
  mount_uploader :avatar, AvatarUploader
end
