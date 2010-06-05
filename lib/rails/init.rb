ActiveSupport.on_load(:active_record) do
  ActiveSupport.on_load(:before_initialize) do
    EncodedAttachment.setup_activerecord
  end
end

ActiveSupport.on_load(:active_resource) do
  EncodedAttachment.setup_activeresource
end