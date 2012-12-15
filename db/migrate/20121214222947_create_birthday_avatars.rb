class CreateBirthdayAvatars < ActiveRecord::Migration
  def change
    create_table :birthday_avatars do |t|
      t.string :avatar

      t.timestamps
    end
  end
end
