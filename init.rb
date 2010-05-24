if Object.const_defined?("ActiveRecord") && Object.const_defined?("Paperclip")
  ActiveRecord::Base.send(:include, EncodedAttachment)
end

if Object.const_defined?("ActiveResource")
  ActiveResource::Base.send(:include, EncodedAttachment)
end