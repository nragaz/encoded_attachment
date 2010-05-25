require 'test_helper'

class ActiveRecordTest < ActiveSupport::TestCase
  load_schema

  test "create user without exception" do
    assert_nothing_raised { User.new(:name => 'John Doe') }
  end
  
end
