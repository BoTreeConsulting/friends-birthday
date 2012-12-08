class CustomMessage < ActiveRecord::Base
  attr_accessible :friend_uid, :message, :user_id
end
