require 'test_helper'

class ActiveResourceTest < ActiveSupport::TestCase
  load_schema

  test "should add get_attachment to ActiveResource::Connection" do
    @connection = ActiveResource::Connection.new("http://localhost/")
    assert @connection.methods.include?("get_attachment")
  end

  test "build user resource without exception" do
    assert_nothing_raised { Api::User.new(:name => 'John Doe') }
  end
  
  test "should add attributes to schema" do
    @user = Api::User.new
    assert @user.known_attributes.include?("name"),                 "Should have name attribute"
    assert @user.known_attributes.include?("avatar_file_name"),     "Should have avatar_file_name attribute"
    assert @user.known_attributes.include?("avatar_file_size"),     "Should have avatar_file_size attribute"
    assert @user.known_attributes.include?("avatar_content_type"),  "Should have avatar_content_type attribute"
    assert @user.known_attributes.include?("avatar_updated_at"),    "Should have avatar_updated_at attribute"
    assert @user.known_attributes.include?("avatar"),               "Should have avatar attribute"
  end
  
  test "should wrap to_xml method" do
    @user = Api::User.new(:name => 'John Doe')
    assert @user.methods.include?("to_xml_with_encoded_avatar"),    "Should have to_xml_with_encoded_avatar"
    assert @user.methods.include?("to_xml_without_encoded_avatar"), "Should have to_xml_without_encoded_avatar"
  end
  
  test "should have changed= and changed? methods" do
    @user = Api::User.new(:name => 'John Doe')
    assert @user.methods.include?("avatar_changed="), "Should have avatar_changed= method"
    assert @user.methods.include?("avatar_changed?"), "Should have avatar_changed method"
  end
  
  test "should set changed?" do
    @user = Api::User.new(:name => 'John Doe')
    assert !(@user.avatar_changed?),  "Avatar should not be changed in new record without attachment"
    
    @user.avatar = File.open("test/fixtures/kitten.jpg")
    assert @user.avatar_changed?,     "Avatar should be changed after attachment is set"
  end
  
  test "should have file= method" do
    @user = Api::User.new(:name => 'John Doe')
    assert @user.methods.include?("avatar=")
  end
  
  test "should have save_file_as method" do
    @user = Api::User.new(:name => 'John Doe')
    assert @user.methods.include?("save_avatar_as")
  end
end
