module ApplicationHelper
  def user_presenter(user)
    Uma::UserPresenter.new(user)
  end
end
