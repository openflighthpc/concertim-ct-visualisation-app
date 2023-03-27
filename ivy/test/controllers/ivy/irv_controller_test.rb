require "test_helper"

class Ivy::IrvControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get irv_show_url
    assert_response :success
  end
end
