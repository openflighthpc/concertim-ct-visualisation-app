#
# Api::V1::UserPresenter
#
# User Presenter for the API
module Api::V1
  class UserPresenter < Emma::Presenter
    # Be selective about what attributes and methods we expose.
    delegate :login, to: :o

    def fullname
      "#{o.firstname} #{o.surname}"
    end
  end
end