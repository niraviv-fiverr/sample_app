require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest

  def setup
    ActionMailer::Base.deliveries.clear
  end
  
  test "invalid signup information" do
  	get signup_path
  	assert_select 'form[action="/signup"]'
  	assert_no_difference 'User.count' do
  		post users_path, params: { user: { name: "",
  										                   email: "user@invalid",
  										                   password: "foo",
  										                   password_confirmation: "bar" } }
  	end
  	assert_template 'users/new'
  	assert_select 'div#error_explanation'
  	assert_select 'div.field_with_errors'
  end

  test "valid signup information with account activation" do
    get signup_path
    assert_difference 'User.count', 1 do
      post users_path, params: { user: { name:  "Example User",
                                         email: "user@example.com",
                                         password:              "password",
                                         password_confirmation: "password" } }
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
    user = assigns(:user)
    assert_not user.activated?
    # Try to log in before activation.
    log_in_as(user)
    assert_not is_logged_in?
    # Invalid activation token
    get edit_account_activation_path("invalid token", email: user.email)
    assert_not is_logged_in?
    # Valid token, wrong email
    get edit_account_activation_path(user.activation_token, email: 'wrong')
    assert_not is_logged_in?
    # Valid activation token
    get edit_account_activation_path(user.activation_token, email: user.email)
    assert user.reload.activated?
    follow_redirect!
    assert_template 'users/show'
    assert is_logged_in?
  end

  test "index and show pages don't display unactivated users" do
    # Sign up a new user
    post users_path, params: { user: { name:  "Example User",
                                       email: "user@example.com",
                                       password:              "password",
                                       password_confirmation: "password" } }
    user = assigns(:user)
    # Log in as someone else
    log_in_as(users(:michael))
    # Load the last page in the index
    get users_path, params: { page: User.paginate(page: 1).total_pages }
    # Ensure the unactivated user doesn't show up
    assert_select "a[href=?]", user_path(user), count: 0
    # Ensure the unactivated user's show page redirects to root
    get user_path(user)
    assert_redirected_to root_url
  end
end