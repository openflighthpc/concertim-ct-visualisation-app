require "test_helper"

class Ivy::IrvControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get ivy_irv_show_url
    assert_response :success
  end
end
