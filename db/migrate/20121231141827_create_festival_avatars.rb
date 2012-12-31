class CreateFestivalAvatars < ActiveRecord::Migration
  def change
    create_table :festival_avatars do |t|
      t.string :avatar
      t.integer :event_id

      t.timestamps
    end
  end
end
