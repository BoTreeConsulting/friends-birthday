class Notification < ActionMailer::Base
  default from: "forchetan01@gmail.com"

  def reminder_email(user_email)
    set_images
    @user_email = user_email
    mail(:to => user_email, :subject => "Reminder::Friends B'day Profile Analysis::You are not connected.")
  end

  def set_images
    logo = File.read(Rails.root.join('app/assets/images/bnr-img.jpg'))
    attachments.inline['bnr-img.jpg'] = {
        :data => logo,
        :mime_type => "image/jpg",
        :encoding => "base64"
    }
  end
end
