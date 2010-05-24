module EncodedAttachment
  VERSION = "0.1"
  
  class << self
    def encode(attachment, style = :original)
      Base64.encode64(File.read(attachment.path(style)) { |f| f.read })
    end
    
    def included(base)
      base.extend ActiveRecordClassMethods if base.to_s == "ActiveRecord::Base"
      base.extend ActiveResourceClassMethods if base.to_s == "ActiveResource::Base"
    end
  end
  
  module ActiveRecordClassMethods
    def encode_attachment_in_xml(name)
      define_method "to_xml_with_encoded_#{name}" do |*args|
        options, block = args
        options ||= {}
        options[:procs] ||= []
        options[:procs] << Proc.new { |options, record|
          file_options = { :type => 'file'}
          if send(name).file?
            file_options.merge!({:name => send("#{name}_file_name"), :"content-type" => send("#{name}_content_type")})
            options[:builder].tag!(name, file_options) {
              options[:builder].cdata! EncodedAttachment.encode(send(name))
            }
          else    
            file_options.merge!({:nil => true})
            options[:builder].tag!(name, "", file_options)
          end
        }
        send("to_xml_without_encoded_#{name}", options, &block)
      end
      
      alias_method_chain :to_xml, :"encoded_#{name}"
    end
  end
end

ActiveRecord::Base.send(:include, EncodedAttachment) if Object.const_defined?("ActiveRecord") && Object.const_defined?("Paperclip")
