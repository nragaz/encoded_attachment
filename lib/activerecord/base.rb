module EncodedAttachment
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
        options[:encode_attachments] = false unless options.has_key?(:encode_attachments)
        options[:procs] ||= []
        if options[:include_attachments]
          # strip Paperclip methods
          options[:except] ||= []
          options[:except] = (options[:except] + [:"#{name}_file_name", :"#{name}_file_size",
                                                  :"#{name}_content_type", :"#{name}_updated_at"]).uniq
          
          # get URL handling variables if :send_urls => true               
          send_urls = send(:class).instance_variable_get("@_attachment_handling")[name][:send_urls]
          root_url = send(:class).instance_variable_get("@_attachment_handling")[name][:root_url] if send_urls
          
          options[:procs] << Proc.new { |options, record|
            file_options = { :type => 'file'}
            if !(new_record? || frozen?) && send(name).file? && (!(send_urls) || options[:encode_attachments])
              file_options.merge! :name => send("#{name}_file_name"), :"content-type" => send("#{name}_content_type")
              options[:builder].tag!(name, file_options) { options[:builder].cdata! EncodedAttachment.encode(send(name)) }
            elsif !(new_record? || frozen?) && send(name).file? && send_urls
              file_options.merge! :type => :string
              url = root_url ? URI.join(root_url, send(name).url(:original, false)) : send(name).url(:original, false)
              options[:builder].tag! "#{name}_url", url, file_options
            elsif send_urls && (new_record? || frozen? || !(send(name).file?))
              file_options.merge! :type => :string, :nil => true
              options[:builder].tag! "#{name}_url", nil, file_options
            else
              # the file can't be included if the record is not persisted yet, because of how Paperclip works
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
end