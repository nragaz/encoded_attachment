require File.expand_path("../lib/encoded_attachment/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "encoded_attachment"
  s.version     = EncodedAttachment::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Nick Ragaz"]
  s.email       = ["nick.ragaz@gmail.com"]
  s.homepage    = "http://github.com/nragaz/encoded_attachment"
  s.summary     = "Handles downloading and uploading Paperclip attachments using Active Resource"
  s.description = "Adds methods to ActiveRecord::Base and ActiveResource::Base to transmit file attachments via REST, either as encoded binary or via a separate URL"

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "encoded_attachment"
  
  s.add_dependency "mime-types"
  # s.add_dependency "paperclip", "~> 2.3"
  # s.add_dependency "activerecord", "~> 2.3"
  # s.add_dependency "activeresource", "~> 2.3"
  
  s.files        = Dir["{lib}/**/*.rb", "LICENSE", "*.md"]
  s.require_path = 'lib'
end