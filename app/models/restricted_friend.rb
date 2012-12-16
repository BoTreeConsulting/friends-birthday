class RestrictedFriend < ActiveRecord::Base
  attr_accessible :uid, :user_id
  belongs_to :user
end
