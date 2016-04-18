class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def lastfm
    @user = User.from_omniauth(request.env['omniauth.auth'])
    if @user.persisted?
      sign_in_and_redirect @user
      flash[:success] = "Hello, #{@user.uid}!"
    elsif @user.save
      sign_in_and_redirect @user
      flash[:success] = "Hello, #{@user.uid}!"
    else
      flash[:error] = "Oops. We couldn't log you in."
      session["devise.facebook_data"] = request.env["omniauth.auth"]
      redirect_to root_path
    end
    binding.pry
  end
end