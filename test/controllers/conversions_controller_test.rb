require "test_helper"

class ConversionsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get conversions_index_url
    assert_response :success
  end
end
