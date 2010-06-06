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
    
    def included(base)
      base.extend ActiveRecordClassMethods if base.to_s == "ActiveRecord::Base"
      if base.to_s == "ActiveResource::Base"
        base.extend ActiveResourceClassMethods
        ActiveResource::Connection.send :include, ActiveResourceConnectionMethods
      end
    end
    
    def setup_activerecord
      if Object.const_defined?('Paperclip')
        ActiveRecord::Base.send(:include, EncodedAttachment)
      else
        raise "Could not load EncodedAttachment::ActiveRecord because Paperclip is not available"
      end
    end
    
    def setup_activeresource
      ActiveResource::Base.send(:include, EncodedAttachment)
    end
  end
end

# Initialization
if defined?(Rails::Railtie)
  ActiveSupport.on_load(:active_record) do
    p "Setting ActiveRecord initialization hook..."
    EncodedAttachment.setup_activerecord
  end
  
  ActiveSupport.on_load(:active_resource) do
    p "Setting ActiveResource initialization hook..."
    EncodedAttachment.setup_activeresource
  end
else
  # Load right away if required outside of Rails initialization
  p "Required encoded_attachment..."
  EncodedAttachment.setup_activerecord if Object.const_defined?('ActiveRecord')
  EncodedAttachment.setup_activeresource if Object.const_defined?('ActiveResource')
end