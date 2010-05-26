require 'test_helper'
require 'fileutils'

class ActiveResourceBaseTest < ActiveSupport::TestCase
  load_schema

  test "should add get_attachment to ActiveResource::Connection" do
    @connection = ActiveResource::Connection.new("http://localhost/")
    assert @connection.methods.include?("get_attachment")
  end

  test "build user resource without exception" do
    assert_nothing_raised { Api::User.new(:name => 'John Doe') }
  end
end

class ActiveResourceMethodsTest < ActiveSupport::TestCase
  setup do
    @user = Api::User.new(:name => 'John Doe')
  end
  
  test "should add attributes to schema" do
    assert @user.known_attributes.include?("name"),                 "Should have name attribute"
    assert @user.known_attributes.include?("avatar_file_name"),     "Should have avatar_file_name attribute"
    assert @user.known_attributes.include?("avatar_file_size"),     "Should have avatar_file_size attribute"
    assert @user.known_attributes.include?("avatar_content_type"),  "Should have avatar_content_type attribute"
    assert @user.known_attributes.include?("avatar_updated_at"),    "Should have avatar_updated_at attribute"
    assert @user.known_attributes.include?("avatar"),               "Should have avatar attribute"
  end
  
  test "should wrap to_xml method" do
    assert @user.methods.include?("to_xml_with_encoded_avatar"),    "Should have to_xml_with_encoded_avatar"
    assert @user.methods.include?("to_xml_without_encoded_avatar"), "Should have to_xml_without_encoded_avatar"
  end
  
  test "should have changed= and changed? methods" do
    assert @user.methods.include?("avatar_changed="), "Should have avatar_changed= method"
    assert @user.methods.include?("avatar_changed?"), "Should have avatar_changed method"
  end
  
  test "should not be changed? in new record" do
    assert !(@user.avatar_changed?)
  end
  
  test "changed? should be true after attachment is set" do
    @user.avatar = File.open("test/fixtures/kitten.jpg")
    assert @user.avatar_changed?
  end
  
  test "should have file= method" do
    assert @user.methods.include?("avatar=")
  end
  
  test "should have file_path= method" do
    assert @user.methods.include?("avatar_path=")
  end
  
  test "should have file_url= method" do
    assert @user.methods.include?("avatar_url=")
  end
  
  test "should have save_file_as method" do
    assert @user.methods.include?("save_avatar_as")
  end
  
  test "should wrap file_updated_at" do
    @user.avatar_updated_at = "Wed May 26 01:29:08 UTC 2010"
    assert @user.avatar_updated_at.is_a?(Time)
  end
end

class ActiveResourceAttributesTest < ActiveSupport::TestCase
  setup do
    @user_record = User.create(:name => 'John Doe', :avatar => File.open("test/fixtures/tapir.jpg"))
    @user = Api::User.new(Hash.from_xml(@user_record.to_xml)['user'])
  end
  
  teardown do
    User.destroy_all
  end
  
  test "should set initial attributes" do
    assert_equal 'tapir.jpg', @user.avatar_file_name,     'Should set name'
    assert_equal 'image/jpeg', @user.avatar_content_type, 'Should set content type'
    assert       @user.avatar.is_a?(StringIO),            'Should set attachment to StringIO'
    assert       !(@user.avatar_changed?),                'Should not be changed?'
  end
  
  test "should set attributes if attachment is nil" do
    @user_record = User.create(:name => 'John Doe', :avatar => nil)
    @user = Api::User.new(Hash.from_xml(@user_record.to_xml)['user'])
    
    assert_nil @user.avatar_file_name,                    'Name should be nil'
    assert_nil @user.avatar_content_type,                 'Content type should be nil'
    assert_nil @user.avatar,                              'Attachment should be nil'
    assert     !(@user.avatar_changed?),                  'Should not be changed?'
  end
  
  test "should update attributes if initial attachment was nil" do
    @user_record = User.create(:name => 'John Doe', :avatar => nil)
    @user = Api::User.new(Hash.from_xml(@user_record.to_xml)['user'])
    @user.attributes = { :avatar => File.open('test/fixtures/kitten.jpg') }

    assert_equal 'kitten.jpg', @user.avatar_file_name,    'Should set name'
    assert_equal 'image/jpeg', @user.avatar_content_type, 'Should set content type'
    assert       @user.avatar.is_a?(File),                'Should set attachment to File'
    assert       @user.avatar_changed?,                   'Should be changed?'
  end
  
  test "should be able to update attachment" do
    @user.avatar = File.open('test/fixtures/kitten.jpg')
    assert_equal 'kitten.jpg', @user.avatar_file_name,    'Should set name'
    assert_equal 'image/jpeg', @user.avatar_content_type, 'Should set content type'
    assert       @user.avatar.is_a?(File),                'Should set attachment to File'
    assert       @user.avatar_changed?,                   'Should be changed?'
  end
  
  test "should be able to update attachment using attributes=" do
    @user.attributes = { :avatar => File.open('test/fixtures/kitten.jpg') }
    assert_equal 'kitten.jpg', @user.avatar_file_name,    'Should set name'
    assert_equal 'image/jpeg', @user.avatar_content_type, 'Should set content type'
    assert       @user.avatar.is_a?(File),                'Should set attachment to File'
    assert       @user.avatar_changed?,                   'Should be changed?'
  end
  
  test "should be able to update attachment using path" do
    @user.avatar_path = 'test/fixtures/kitten.jpg'
    assert_equal 'kitten.jpg', @user.avatar_file_name,    'Should set name'
    assert_equal 'image/jpeg', @user.avatar_content_type, 'Should set content type'
    assert       @user.avatar.is_a?(File),                'Should set attachment to File'
    assert       @user.avatar_changed?,                   'Should be changed?'
  end
  
  test "should be able to save attachment" do
    assert_nothing_raised { @user.save_avatar_as "test/test_file.jpg" }
    File.delete 'test/test_file.jpg' if File.exist?('test/test_file.jpg')
  end
  
  test "should overwrite attachment if file exists" do
    FileUtils.touch 'test/test_file.jpg'
    assert_nothing_raised { @user.save_avatar_as 'test/test_file.jpg' }
    File.delete 'test/test_file.jpg' if File.exist?('test/test_file.jpg')
  end
  
  test "should not overwrite attachment if file exists and save_as is called with false" do
    FileUtils.touch 'test/test_file.jpg'
    assert_raises(RuntimeError) { @user.save_avatar_as 'test/test_file.jpg', false }
    File.delete 'test/test_file.jpg' if File.exist?('test/test_file.jpg')
  end
end

class ActiveResourceConnectionMethods < ActiveSupport::TestCase
  def setup
    @user_record  = User.create(:name => 'John Doe', :avatar => File.open('test/fixtures/kitten.jpg'),
                                :avatar_remote => File.open('test/fixtures/tapir.jpg'))
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get    "/users/#{@user_record.id}.xml", {}, @user_record.to_xml
      mock.post   "/users.xml", {}, @user_record.to_xml, 201, "Location" => "/people/1.xml"
      mock.put    "/users/#{@user_record.id}.xml", {}, nil, 204
      mock.delete "/users/#{@user_record.id}.xml", {}, nil, 200
      mock.get    "/users/#{@user_record.id}.jpg", { 'Accept' => 'image/jpeg' }, File.read('test/fixtures/tapir.jpg'),
                  200, "Content-Type" => "image/jpeg"
    end
  end
  
  teardown do
    User.destroy_all
  end
  
  test "HTTP mock is working" do
    @user = Api::User.find(@user_record.id)
    assert ActiveResource::HttpMock.requests.include?(ActiveResource::Request.new(:get, "/users/#{@user_record.id}.xml")),
           "Should receive find request"
    assert ActiveResource::HttpMock.requests.include?(ActiveResource::Request.new(:get, "/users/#{@user_record.id}.jpg")),
           "Should receive avatar_remote image request"
  end
  
  test "should receive and parse XML, including a remote attachment" do
    @user = Api::User.find(@user_record.id)
    
    assert_equal 'kitten.jpg', @user.avatar_file_name,    'Should set name'
    assert_equal 'image/jpeg', @user.avatar_content_type, 'Should set content type'
    assert       @user.avatar.is_a?(StringIO),            'Should set attachment to StringIO'
    assert       !(@user.avatar_changed?),                'Should not be changed?'
    
    assert_equal "#{@user_record.id}.jpg", @user.avatar_remote_file_name, 'Should set remote name'
    assert_equal 'image/jpeg', @user.avatar_remote_content_type, 'Should set remote content type'
    assert       @user.avatar_remote.is_a?(StringIO),            'Should set remote attachment to StringIO'
    assert       !(@user.avatar_remote_changed?),                'Remote should not be changed?'
  end
  
  test "should POST a new user" do
    @user = Api::User.new(:name => 'John Doe')
    @user.save
    assert ActiveResource::HttpMock.requests.include?(ActiveResource::Request.new(:post, "/users.xml"))
  end
  
  test "should PUT an update" do
    @user = Api::User.find(@user_record.id)
    @user.name = 'Jane Doe'
    @user.save
    assert ActiveResource::HttpMock.requests.include?(ActiveResource::Request.new(:put, "/users/#{@user_record.id}.xml"))
  end
  
  test "should DELETE when destroyed" do
    @user = Api::User.find(@user_record.id)
    @user.destroy
    assert ActiveResource::HttpMock.requests.include?(ActiveResource::Request.new(:delete, "/users/#{@user_record.id}.xml")),
           "Should have sent a DELETE request"
  end
end

class ActiveResourceXMLGenerationTest < ActiveSupport::TestCase
  def setup
    @user_record = User.create(:name => 'John Doe', :avatar => File.open("test/fixtures/tapir.jpg"),
                               :avatar_remote => File.open('test/fixtures/kitten.jpg'))
    ActiveResource::HttpMock.respond_to do |mock|
       mock.get    "/users/#{@user_record.id}.xml", {}, @user_record.to_xml
       mock.post   "/users.xml", {}, @user_record.to_xml, 201, "Location" => "/people/1.xml"
       mock.put    "/users/#{@user_record.id}.xml", {}, nil, 204
       mock.delete "/users/#{@user_record.id}.xml", {}, nil, 200
       mock.get    "/users/#{@user_record.id}.jpg", { 'Accept' => 'image/jpeg' }, File.read('test/fixtures/tapir.jpg'),
                   200, "Content-Type" => "image/jpeg"
    end
    @user = Api::User.find(@user_record.id)
  end
  
  def teardown
    User.destroy_all
  end
  
  test "should not generate XML tags because the files haven't changed" do
    user_xml = Hash.from_xml(@user.to_xml)['user']
    assert !(user_xml.has_key?('avatar')),         'Should not have avatar tag'
    assert !(user_xml.has_key?('avatar_remote')),  'Should not have avatar_remote tag'
  end
  
  test "should generate XML tags when the files have changed" do
    @user.avatar_path = 'test/fixtures/kitten.jpg'
    @user.avatar_remote = File.open("test/fixtures/tapir.jpg")
    user_xml = Hash.from_xml(@user.to_xml)['user']
    assert user_xml.has_key?('avatar'),         'Should have avatar tag'
    assert user_xml.has_key?('avatar_remote'),  'Should have avatar_remote tag'
    
    assert user_xml['avatar'].is_a?(StringIO),  'Should be a StringIO'
    assert_equal 'kitten.jpg', user_xml['avatar'].original_filename, 'Should have the original filename'
  end
  
  test "should not generate XML tags when user is new" do
    user_xml = Hash.from_xml(Api::User.new(:name => 'Jane Doe').to_xml)['user']
    assert !(user_xml.has_key?('avatar')),         'Should not have avatar tag'
    assert !(user_xml.has_key?('avatar_remote')),  'Should not have avatar_remote tag'
  end
  
  test "should generate XML tags when user is new and files have been assigned" do
    user_xml = Hash.from_xml(Api::User.new(:name => 'Jane Doe', :avatar => File.open("test/fixtures/tapir.jpg"),
                                           :avatar_remote => File.open('test/fixtures/kitten.jpg')).to_xml)['user']
    assert user_xml.has_key?('avatar'),         'Should have avatar tag'
    assert user_xml.has_key?('avatar_remote'),  'Should have avatar_remote tag'
  end
  
  test "should create a User from XML" do
    @new_user = User.new.from_xml Api::User.new(:name => 'Jane Doe', :avatar => File.open("test/fixtures/tapir.jpg"),
                                                :avatar_remote => File.open('test/fixtures/kitten.jpg')).to_xml
    assert @new_user.save,                                       'User should save'
    assert @new_user.avatar.file?,                               'User should have avatar file'
    assert File.exist?(@new_user.avatar_remote.path(:original)), 'User\'s avatar remote file should exist'
  end
  
  test "should update a User's files from XML" do
    @user.avatar = File.open('test/fixtures/kitten.jpg')
    @user_record.update_attributes Hash.from_xml(@user.to_xml)['user']
    assert_equal  'kitten.jpg', @user_record.avatar_file_name,      'File name updated'
    assert        File.exist?(@user_record.avatar.path(:original)), 'File saved'
  end
end