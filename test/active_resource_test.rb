require 'test_helper'

class ActiveResourceTest < ActiveSupport::TestCase
  load_schema

  test "create user resource without exception" do
    assert_nothing_raised { Api::User.new(:name => 'John Doe') }
  end
end
