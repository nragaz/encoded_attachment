module EncodedAttachment
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
        return "File not set - cannot be saved" if attributes[name].nil? || !(attributes[name].respond_to?(:read))
        path, overwrite = args
        overwrite = true if overwrite.nil?
        unless !(overwrite) && File.exist?(path)
          send(name).pos = 0
          File.open(path, 'w') { |f| f << send(name).read }
          return true
        else
          raise "File not saved - file already exists at #{path}"
        end
      end
      
      alias_method_chain :to_xml, :"encoded_#{name}"
    end
    
  end
end