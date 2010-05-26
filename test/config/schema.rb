ActiveRecord::Schema.define(:version => 0) do
  create_table :users, :force => true do |t|
    t.string    "name"
    
    t.string    "avatar_file_name"
    t.string    "avatar_content_type"
    t.integer   "avatar_file_size"
    t.datetime  "avatar_updated_at"
    
    t.string    "avatar_remote_file_name"
    t.string    "avatar_remote_content_type"
    t.integer   "avatar_remote_file_size"
    t.datetime  "avatar_remote_updated_at"
    
    t.timestamps
  end
end