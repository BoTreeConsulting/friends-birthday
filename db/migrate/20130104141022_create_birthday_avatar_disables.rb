class CreateBirthdayAvatarDisables < ActiveRecord::Migration
  def change
    create_table :birthday_avatar_disables do |t|
      t.integer :user_id
      t.string :friend_uid
      t.boolean :disabled

      t.timestamps
    end
  end
end
