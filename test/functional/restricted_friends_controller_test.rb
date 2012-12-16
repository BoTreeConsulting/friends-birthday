require 'test_helper'

class RestrictedFriendsControllerTest < ActionController::TestCase
  setup do
    @restricted_friend = restricted_friends(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:restricted_friends)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create restricted_friend" do
    assert_difference('RestrictedFriend.count') do
      post :create, restricted_friend: { uid: @restricted_friend.uid, user_id: @restricted_friend.user_id }
    end

    assert_redirected_to restricted_friend_path(assigns(:restricted_friend))
  end

  test "should show restricted_friend" do
    get :show, id: @restricted_friend
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @restricted_friend
    assert_response :success
  end

  test "should update restricted_friend" do
    put :update, id: @restricted_friend, restricted_friend: { uid: @restricted_friend.uid, user_id: @restricted_friend.user_id }
    assert_redirected_to restricted_friend_path(assigns(:restricted_friend))
  end

  test "should destroy restricted_friend" do
    assert_difference('RestrictedFriend.count', -1) do
      delete :destroy, id: @restricted_friend
    end

    assert_redirected_to restricted_friends_path
  end
end
