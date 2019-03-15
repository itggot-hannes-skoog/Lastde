require_relative "spec_helper"

user = ("user" + SecureRandom.urlsafe_base64(4, false))
feature "Register" do
  scenario "Register user" do
    visit "/"
    click_button "Register"
    sleep 1
    fill_in "username", with: user
    fill_in "email", with: (user + "@gmail.com")
    fill_in "pwd", with: "123"
    click_button "Register"
    sleep 2
    expect(page).to have_content user
  end

  scenario "Test login form" do
    visit "/"
    fill_in "username", with: user
    fill_in "password", with: "123"
    click_button "Login"
    sleep 2
    expect(page).to have_content "successful"
  end
end

feature "Create sub" do
  scenario "Create sub" do
    visit "/"
    fill_in "username", with: user
    fill_in "password", with: "123"
    click_button "Login"
    visit "/l/new"
    fill_in "name", with: user + "sub"
    click_button "Create"
    sleep 2
    expect(page).to have_content user.upcase + "SUB"
  end

  scenario "Make post" do
    visit "/l/" + user + "sub"
    fill_in "username", with: user
    fill_in "password", with: "123"
    click_button "Login"
    click_button "Write post"
    sleep 1
    fill_in "title", with: user + "post"
    fill_in "textbody", with: "ich bin " + user + ". guten tag"
    click_button "Post"
  end
end
