require 'base64'

module EncodedAttachment
  class << self
    def encode(attachment, style = :original)
      encode_io( File.open(attachment.path(style)) )
    end
    
    def encode_io(io)
      io.pos = 0
      Base64.encode64(io.read)
    end
    
    def setup_activerecord
      require File.dirname(__FILE__) + '/activerecord/base'
      ActiveRecord::Base.extend ActiveRecordClassMethods
    end
    
    def setup_activeresource
      require File.dirname(__FILE__) + '/activeresource/base'
      require File.dirname(__FILE__) + '/activeresource/connection'
      ActiveResource::Base.extend ActiveResourceClassMethods
      ActiveResource::Connection.send :include, ActiveResourceConnectionMethods
    end
  end
end

# Initialization
if defined?(Rails::Railtie)
  ActiveSupport.on_load(:active_record) do
    EncodedAttachment.setup_activerecord
  end
  
  ActiveSupport.on_load(:active_resource) do
    EncodedAttachment.setup_activeresource
  end
  
  ActiveSupport.on_load(:before_initialize) do
    # workaround until above load hook works
    EncodedAttachment.setup_activeresource \
      unless !defined?(ActiveResource) || ActiveResource::Base.methods.include?('has_encoded_attachment')
  end
else
  # Load right away if required outside of Rails initialization
  EncodedAttachment.setup_activerecord if defined?(ActiveRecord)
  EncodedAttachment.setup_activeresource if defined?(ActiveResource)
end