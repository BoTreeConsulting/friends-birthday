class CreateCustomMessages < ActiveRecord::Migration
  def change
    create_table :custom_messages do |t|
      t.integer :user_id
      t.string :friend_uid
      t.text :message

      t.timestamps
    end
  end
end
