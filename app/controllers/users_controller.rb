class UsersController < ApplicationController

  def changelanguage
    current_locale = current_user.locale
    if current_locale == "en"
      new_locale = "de"
    elsif current_locale == "de"
      new_locale = "en"
    elsif not current_locale
      new_locale = "de"
    else
      raise "Unknown locale #{current_locale}"
    end

    current_user.update_attribute(:locale, new_locale)

    redirect_to :back
  end

end
