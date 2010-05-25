require 'test_helper'

class EncodedAttachmentTest < ActiveSupport::TestCase
  load_schema
  
  class User < ActiveRecord::Base
    has_attached_file        :avatar
    encode_attachment_in_xml :avatar
  end
  
  module Api
    class User < ActiveResource::Base
      self.site = "http://localhost:3000"
      
      has_encoded_attachment :avatar
      
      schema do
        string "name"
      end
    end
  end
  
  # Replace this with your real tests.
  test "create user" do
    assert_nothing_raised { User.new(:name => 'John Doe') }
  end
  
  test "create user resource" do
    assert_nothing_raised { Api::User.new(:name => 'John Doe') }
  end
end
