require 'base64'
require 'activerecord/base'
require 'activeresource/base'
require 'activeresource/connection'

module EncodedAttachment
  VERSION = "0.1"
  
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
  end
end
