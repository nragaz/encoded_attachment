require 'test_helper'

class ActiveRecordTest < ActiveSupport::TestCase
  load_schema

  test "create and save user without exception" do
    assert_nothing_raised {
      @user = User.new(:name => 'John Doe', :avatar => File.open("test/fixtures/kitten.jpg"))
      @user.save!
    }
    @user.destroy
  end
  
end
