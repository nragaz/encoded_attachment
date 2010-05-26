module EncodedAttachment
  module ActiveResourceConnectionMethods
    def get_attachment(path, headers = {})
      request_headers = build_request_headers(headers, :get, self.site.merge(path))
      with_auth { request(:get, path, request_headers) }
    end
  end
end