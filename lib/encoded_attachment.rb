require 'base64'
require File.dirname(__FILE__) + '/activerecord/base'
require File.dirname(__FILE__) + '/activeresource/base'
require File.dirname(__FILE__) + '/activeresource/connection'

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
      if defined?(Paperclip)
        ActiveRecord::Base.extend ActiveRecordClassMethods
      else
        raise "Could not include EncodedAttachment methods in ActiveRecord because Paperclip is not loaded"
      end
    end
    
    def setup_activeresource
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
else
  # Load right away if required outside of Rails initialization
  EncodedAttachment.setup_activerecord if defined?(ActiveRecord)
  EncodedAttachment.setup_activeresource if defined?(ActiveResource)
end