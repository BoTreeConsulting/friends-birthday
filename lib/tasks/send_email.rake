namespace :friends_birthday  do
  require 'koala'
  desc "Sending Email to users for reminding to reconnect"
  task :send_email_notification => :environment do
    user_emails  = User.pluck(:email)
    if user_emails.present?
      #user_emails.each do |user_email|
        begin
          Notification.reminder_email("forchetan01@gmail.com")
          puts "Email has been send successfully to forchetan01"
        rescue Exception => e
          puts "Email Not send=>>>>>>> #{e.message}"
        end
      #end
    end
  end
end

