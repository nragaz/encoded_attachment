if Object.const_defined?("ActiveRecord") && Object.const_defined?("Paperclip")
  ActiveRecord::Base.send(:include, EncodedAttachment)
end