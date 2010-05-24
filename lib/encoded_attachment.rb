module EncodedAttachment
  VERSION = "0.1"
  
  class << self
    def encode(attachment, style = :original)
      encode_io( File.open(attachment.path(style)) )
    end
    
    def encode_io(io)
      Base64.encode64(io.read)
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
  
  module ActiveResourceClassMethods
    # Let's you set a path to a file in an Active Resource model, and have this blast away whatever attributes already existed.
    def has_encoded_attachment(name)
      schema do
        string    "#{name}_file_name", "#{name}_content_type"
        integer   "#{name}_file_size"
        attribute "#{name}_updated_at", "string"
        attribute name
      end
      
      define_method "#{name}_updated_at" do
        attributes["#{name}_updated_at"].to_time if attributes["#{name}_updated_at"].is_a?(String)
      end
      
      define_method "to_xml_with_encoded_#{name}" do |*args|
        options, block = args
        options ||= {}
        options[:procs] ||= []
        options[:procs] << Proc.new { |options, record|
          file_options = { :type => 'file'}
          if send("#{name}_path?")
            file_options.merge!({:name => send("#{name}_file_name"), :"content-type" => send("#{name}_content_type")})
            options[:builder].tag!(name, file_options) {
              options[:builder].cdata! EncodedAttachment.encode_io(send(name))
            }
          else    
            file_options.merge!({:nil => true})
            options[:builder].tag!(name, "", file_options)
          end
        }
        send("to_xml_without_encoded_#{name}", options, &block)
      end
      
      define_method "#{name}_path=" do |file_path|
        send("#{name}=", File.open(file_path))
        send("#{name}_file_name=", File.basename(file_path))
        send("#{name}_content_type=", MIME::Types.type_for(File.basename(file_path)).first.content_type)
        send("attributes").delete("#{name}_file_size")
      end
      
      define_method "#{name}=" do |io|
        if io.path
          send("#{name}_file_name=", File.basename(file_path))
          send("#{name}_content_type=", MIME::Types.type_for(File.basename(file_path)).first.content_type)
        end
        send("attributes").send("[]=", "#{name}", io)
        send("attributes").delete("#{name}_file_size")
      end
      
      alias_method_chain :to_xml, :"encoded_#{name}"
    end
    
  end
end
