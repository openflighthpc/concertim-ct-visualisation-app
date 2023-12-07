class SignInPage
  include Capybara::DSL
  include Rails.application.routes.url_helpers

  def visit_page
    visit new_user_session_path
    self
  end

  def sign_in(username:, password:)
    fill_in "Username", with: username
    fill_in "Password", with: password
    click_on "Login"
    self
  end
end

class UserIndexPage
  include Capybara::DSL
  include Rails.application.routes.url_helpers

  attr_reader :pagination

  def visit_page(opts={})
    visit users_path(opts)
    @rt = ResourceTable.new(find('.resource_table'))
    @pagination = ResourceTablePagination.new(find('.pagination_controls'))
    self
  end

  def assert_table_contains_user(user)
    @rt.assert_body_contains(user.id)
    @rt.assert_body_contains(user.login)
    @rt.assert_body_contains(user.name)
  end

  def assert_not_table_contains_user(user)
    @rt.assert_not_body_contains(user.id)
  end
end

class ResourceTable
  include Capybara::DSL
  include Capybara::RSpecMatchers
  include RSpec::Matchers

  def initialize(node)
    @node = node
    @body = node.find('tbody')
  end

  def assert_body_contains(content)
    expect(@body).to have_content(content)
  end

  def assert_not_body_contains(content)
    expect(@body).not_to have_content(content)
  end
end

class ResourceTablePagination
  include Capybara::DSL
  include Capybara::RSpecMatchers
  include RSpec::Matchers

  def initialize(node)
    @node = node
  end

  def assert_paginated(from:, to:, of:)
    if from == 1 && to == of
      expect(@node).to have_content "Displaying 11 items"
    end
    self
  end

  def assert_link(type, state)
    if state == :disabled
      expect(@node).to have_css(".page.#{type}.disabled")
    elsif state == :enabled
      expect(@node).not_to have_css(".page.#{type}.disabled")
      expect(@node).to have_css(".page.#{type}")
      expect(@node).to have_css("a[rel='#{type}']")
    else
      raise ArgumentError, "unexpected state #{state.inspect}; expected :disabled or :enabled"
    end
    self
  end

  def click_next_link
    @node.click_link "Next"
  end

  def click_prev_link
    @node.click_link "Prev"
  end
end
