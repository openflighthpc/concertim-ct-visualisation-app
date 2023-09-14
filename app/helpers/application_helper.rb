module ApplicationHelper
  def user_presenter(user)
    UserPresenter.new(user)
  end
end
