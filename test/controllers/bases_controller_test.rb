require 'test_helper'

class BasesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get bases_index_url
    assert_response :success
  end

end
