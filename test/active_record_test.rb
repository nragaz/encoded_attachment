require 'test_helper'

class ActiveRecordCreationTest < ActiveSupport::TestCase
  load_schema

  test "build, save and destroy model without exception" do
    assert_nothing_raised {
      @user = User.new(:name => 'John Doe', :avatar => File.open("test/fixtures/kitten.jpg"))
      @user.save!
      @user.destroy
    }
  end
end

class ActiveRecordUserWithEncodedAttachmentsTest < ActiveSupport::TestCase
  load_schema
  
  setup do
    @user = User.create(:name => 'John Doe', :avatar => File.open("test/fixtures/kitten.jpg"))
  end
  
  teardown do
    User.destroy_all
  end
  
  test "should wrap to_xml methods" do
    assert @user.methods.include?("to_xml_with_encoded_avatar"),    'Should include wrapped method'
    assert @user.methods.include?("to_xml_without_encoded_avatar"), 'Should include unwrapped method'
  end

  test "should generate file tags" do
    user_xml = Hash.from_xml(@user.to_xml)['user']
    
    assert       user_xml.has_key?('avatar'),                         'Should have avatar key'
    assert_equal 'kitten.jpg', user_xml['avatar'].original_filename,  'Should set avatar filename'
    assert_equal 'image/jpeg', user_xml['avatar'].content_type,       'Should set avatar content type'
  end

  test "should not generate file tags with :include_attachments => false" do
    assert !(Hash.from_xml(@user.to_xml(:include_attachments => false))['user'].has_key?('avatar'))
  end

  test "file tag should be nil on new or destroyed records" do
    @new_user = User.new(:name => 'John Doe', :avatar => File.open("test/fixtures/kitten.jpg"))
    assert Hash.from_xml(@new_user.to_xml)['user']['avatar'].nil?
  end
  
  test "file tag should be nil on destroyed records" do
    @user.destroy
    assert Hash.from_xml(@user.to_xml)['user']['avatar'].nil?
  end

  test "should copy file attributes from an existing record to a new one" do
    @new_user = User.new.from_xml @user.to_xml

    assert_equal 'John Doe', @new_user.name,                  'New user name should be the same'
    assert       @new_user.avatar.file?,                      'New user should have a file'
    assert       @new_user.save,                              'New user should save'
    assert_equal 'kitten.jpg', @new_user.avatar_file_name,    'New user should have correct file name'
    assert_equal 'image/jpeg', @new_user.avatar_content_type, 'New user should have correct content type'
  end

  test "should update attributes from one record to another" do
    @other_user = User.create(:name => 'Bill Tapir', :avatar => File.open("test/fixtures/tapir.jpg"))
    @other_user.update_attributes Hash.from_xml(@user.to_xml)['user']

    assert_equal 'John Doe', @other_user.name,                  'Other user name should be the same'
    assert       @other_user.avatar.file?,                      'Other user should have a file'
    assert_equal 'kitten.jpg', @other_user.avatar_file_name,    'Other user should have correct file name'
    assert_equal 'image/jpeg', @other_user.avatar_content_type, 'Other user should have correct content type'
  end
end

class ActiveSupportWithURLAttachmentsTest < ActiveSupport::TestCase  
  load_schema
  
  setup do
    @user = User.create(:name => 'John Doe', :avatar_url => File.open("test/fixtures/kitten.jpg"))
  end
  
  teardown do
    User.destroy_all
  end

  test "should create avatar_url_url tags" do
    assert Hash.from_xml(@user.to_xml)['user'].has_key?('avatar_url_url')
  end
  
  test "should not create avatar_url_url tags with :include_attachments => false" do
    assert !(Hash.from_xml(@user.to_xml(:include_attachments => false))['user'].has_key?('avatar_url_url'))
  end
  
  test "should not create avatar_url tags" do
    assert !(Hash.from_xml(@user.to_xml)['user'].has_key?('avatar_url'))
  end
  
  test "avatar_url_url tags should be nil if the user is new" do
    @new_user = User.new(:name => 'John Doe', :avatar_url => File.open("test/fixtures/kitten.jpg"))
    assert Hash.from_xml(@new_user.to_xml)['user']['avatar_url_url'].nil?,    'Should have nil URL tag'
    assert !(Hash.from_xml(@new_user.to_xml)['user'].has_key?('avatar_url')), 'Should not have file tag'
  end
  
  test "avatar_url_url tags should be nil if the user is destroyed" do
    @user.destroy
    assert Hash.from_xml(@user.to_xml)['user']['avatar_url_url'].nil?,        'Should have nil URL tag'
    assert !(Hash.from_xml(@user.to_xml)['user'].has_key?('avatar_url')),     'Should not have file tag'
  end
  
  test "avatar_url_url tag should point to the image's URL" do
    assert_equal "http://localhost/users/#{@user.id}.jpg", Hash.from_xml(@user.to_xml)['user']['avatar_url_url']
  end
  
  test "avatar_url_url tag should not raise exception when applied to another ActiveRecord" do
    assert_nothing_raised { @new_user = User.new.from_xml(@user.to_xml) }
  end
  
  test "avatar_url_url tag should not set the file when applied to another ActiveRecord" do
    @new_user = User.new.from_xml(@user.to_xml)
    assert !(@new_user.avatar_url.file?)
  end
  
  test "avatar_url_url tag should not be generated with :encode_attachments => true" do
    assert !(Hash.from_xml(@user.to_xml(:encode_attachments => true))['user'].has_key?('avatar_url_url'))
  end
  
  test "avatar_url file tag should be generated with :encode_attachments => true" do
    assert Hash.from_xml(@user.to_xml(:encode_attachments => true))['user'].has_key?('avatar_url')
  end
  
  test "avatar_url file tag should include all necessary attributes" do
    user_xml = Hash.from_xml(@user.to_xml(:encode_attachments => true))['user']
    assert        user_xml.has_key?('avatar_url')
    assert_equal  'kitten.jpg', user_xml['avatar_url'].original_filename, 'Filename should be set'
    assert_equal  'image/jpeg', user_xml['avatar_url'].content_type,      'Content type should be set'
  end
end
