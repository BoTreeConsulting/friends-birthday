require 'test_helper'

class CustomMessagesControllerTest < ActionController::TestCase
  setup do
    @custom_message = custom_messages(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:custom_messages)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create custom_message" do
    assert_difference('CustomMessage.count') do
      post :create, custom_message: { friend_uid: @custom_message.friend_uid, message: @custom_message.message, user_id: @custom_message.user_id }
    end

    assert_redirected_to custom_message_path(assigns(:custom_message))
  end

  test "should show custom_message" do
    get :show, id: @custom_message
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @custom_message
    assert_response :success
  end

  test "should update custom_message" do
    put :update, id: @custom_message, custom_message: { friend_uid: @custom_message.friend_uid, message: @custom_message.message, user_id: @custom_message.user_id }
    assert_redirected_to custom_message_path(assigns(:custom_message))
  end

  test "should destroy custom_message" do
    assert_difference('CustomMessage.count', -1) do
      delete :destroy, id: @custom_message
    end

    assert_redirected_to custom_messages_path
  end
end
