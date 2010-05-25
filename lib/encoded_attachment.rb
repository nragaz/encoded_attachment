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
  
  module ActiveRecordClassMethods
    def encode_attachment_in_xml(name, attachment_options={})
      attachment_options[:send_urls] = false unless attachment_options[:send_urls]
      
      @_attachment_handling ||= {}
      @_attachment_handling[name] = {}
      @_attachment_handling[name][:send_urls] = attachment_options[:send_urls]
      @_attachment_handling[name][:root_url] = attachment_options[:root_url] || nil
      
      if attachment_options[:send_urls]
        # Placeholder method to avoid MethodMissing exceptions on Model.from_xml(Model.to_xml)
        define_method "#{name}_url=" do |file_url|
          nil
        end
      end
      
      define_method "to_xml_with_encoded_#{name}" do |*args|
        # You can exclude file tags completely by using :include_files => false
        # If :send_urls => true, force file encoding using :encode => true
        options, block = args
        
        options ||= {}
        options[:include_attachments] = true unless options.has_key?(:include_attachments)
        options[:encode] = false unless options.has_key?(:encode)
        options[:procs] ||= []
        
        if options[:include_attachments]
          options[:procs] << Proc.new { |options, record|
            file_options = { :type => 'file'}
            if !(new_record? || frozen?) && send(name).file? \
               && (!(send(:class).instance_variable_get("@_attachment_handling")[name][:send_urls]) || options[:encode])
              file_options.merge! :name => send("#{name}_file_name"), :"content-type" => send("#{name}_content_type")
              options[:builder].tag!(name, file_options) { options[:builder].cdata! EncodedAttachment.encode(send(name)) }
            elsif !(new_record? || frozen?) && send(name).file? \
                  && send(:class).instance_variable_get("@_attachment_handling")[name][:send_urls]
              file_options.merge! :type => :string
              root_url = send(:class).instance_variable_get("@_attachment_handling")[name][:root_url]
              url_path = send(name).url(:original)
              url = root_url ? URI.join(root_url, url_path) : url_path
              options[:builder].tag!  "#{name}_url", url, file_options
            else
              # the file can't be included if the record is not persisted yet because of how Paperclip works
              file_options.merge! :nil => true
              options[:builder].tag! name, "", file_options
            end
          }
        end
        
        send("to_xml_without_encoded_#{name}", options, &block)
      end
      
      alias_method_chain :to_xml, :"encoded_#{name}"
    end
  end
  
  module ActiveResourceClassMethods
    def has_encoded_attachment(name)
      schema do
        string    "#{name}_file_name", "#{name}_content_type"
        integer   "#{name}_file_size"
        attribute "#{name}_updated_at", "string"
        attribute name, "string"
      end
      
      define_method "#{name}_updated_at" do
        attributes["#{name}_updated_at"].to_time if attributes["#{name}_updated_at"].is_a?(String)
      end
      
      define_method "to_xml_with_encoded_#{name}" do |*args|
        # Normally, the file's XML is only included if the file has been changed in the resource
        # using file= or file_path= or file_url=
        # You can force file tag generation (i.e. even if the file has not changed) by using to_xml(:include_files => true)
        options, block = args
        
        options ||= {}
        options[:except] ||= []
        options[:except] = (options[:except] + [:"#{name}", :"#{name}_updated_at", :"#{name}_file_size"]).uniq
        options[:except] = (options[:except] + [:"#{name}_file_name", :"#{name}_content_type"]).uniq unless send("#{name}_changed?")
        options[:procs] ||= []
        
        options[:procs] << Proc.new { |options, record|
          file_options = { :type => 'file'}
          if send("#{name}_changed?") || options[:include_files]
            file_options.merge!   :name => send("#{name}_file_name"), :"content-type" => send("#{name}_content_type")
            options[:builder].tag!(name, file_options) { options[:builder].cdata! EncodedAttachment.encode_io(send(name)) }
          elsif new_record?
            file_options.merge!     :nil => true
            options[:builder].tag!  name, "", file_options
          end
        }
        
        send "to_xml_without_encoded_#{name}", options, &block
      end
      
      define_method "#{name}_changed=" do |bool|
        instance_variable_set(:"@#{name}_changed", bool)
      end
      
      define_method "#{name}_changed?" do
        instance_variable_get(:"@#{name}_changed") || false
      end
      
      define_method "#{name}_path=" do |file_path|
        send "#{name}=",              File.open(file_path)
        send "#{name}_file_name=",    File.basename(file_path)
        send "#{name}_content_type=", MIME::Types.type_for(File.basename(file_path)).first.content_type
      end
      
      define_method "#{name}_url=" do |file_url|
        url = URI.parse(file_url)
        send "#{name}=",              StringIO.new(send(:connection).get_attachment(url.path).read_body)
        send "#{name}_file_name=",    File.basename(url.path)
        send "#{name}_content_type=", MIME::Types.type_for(File.basename(url.path)).first.content_type
      end
      
      define_method "#{name}=" do |io|
        send "#{name}_changed=", true if new_record? || attributes[name].nil?
        if io.path
          send "#{name}_file_name=",    io.original_filename
          send "#{name}_content_type=", MIME::Types.type_for(io.original_filename).first.content_type
        end
        attributes[name] = io
        attributes.delete "#{name}_url"
        attributes.delete "#{name}_file_size"
        attributes.delete "#{name}_updated_at"
      end
      
      define_method "save_#{name}_as" do |*args|
        path, overwrite = args
        overwrite = true if overwrite.nil?
        unless !(overwrite) && File.exist?(path)
          send(name).pos = 0
          File.open(path, 'w') { |f| f << send(name).read }
        else
          return false
        end
      end
      
      alias_method_chain :to_xml, :"encoded_#{name}"
    end
    
  end
  
  module ActiveResourceConnectionMethods
    def get_attachment(path, headers = {})
      with_auth { request(:get, path, build_request_headers(headers, :get, self.site.merge(path))) }
    end
  end
end
