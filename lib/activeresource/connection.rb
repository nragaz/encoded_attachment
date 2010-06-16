module EncodedAttachment
  module ActiveResourceConnectionMethods
    def get_attachment(path, headers = {})
      with_auth { request(:get, path, build_request_headers(headers, :get, self.site.merge(path))).body }
    end
  end
end