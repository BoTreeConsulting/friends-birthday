class Event < ActiveRecord::Base
  attr_accessible :on, :title
  belongs_to :festival_avatar
end
