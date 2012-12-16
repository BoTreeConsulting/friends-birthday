class CreateRestrictedFriends < ActiveRecord::Migration
  def change
    create_table :restricted_friends do |t|
      t.string :uid
      t.integer :user_id

      t.timestamps
    end
  end
end
