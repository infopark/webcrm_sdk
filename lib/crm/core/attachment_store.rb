module Crm; module Core
  # +AttachmentStore+ represents an attachment of an {Activity::Comment activity comment}.
  #
  # To upload a file as an attachment, add it to +comment_attachments+. The SDK will automatically
  # upload the content of the file.
  #
  # Note that this method of uploading an attachment using a browser will upload the file twice.
  # It is first uploaded to the ruby application (e.g. Rails) which then uploads it to AWS S3.
  #
  # To upload the attachment directly to AWS S3 (i.e. bypassing the ruby application),
  # please proceed as follows:
  #
  # 1. Request an upload permission
  #    ({Crm::Core::AttachmentStore.generate_upload_permission AttachmentStore.generate_upload_permission}).
  #    The response grants the client permission to upload a file to a given key on AWS S3.
  #    This permission is valid for one hour.
  # 2. Upload the file to the URL (+permission.url+ or
  #    +permission.uri+), together with the fields (+permission.fields+) as parameters.
  #    AWS S3 itself then verifies the signature of these parameters prior to accepting the upload.
  # 3. Attach the upload to a new activity comment by setting its +comment_attachments+ attribute
  #    to an array of upload IDs. The client may append filenames to the upload IDs for producing
  #    download URLs with proper filenames later on.
  #
  #    The format of +comment_attachments+ is
  #    <tt>["upload_id/filename.ext", ...]</tt>,
  #    e.g. <tt>["e13f0d960feeb2b2903bd/screenshot.jpg"]</tt>.
  #    Infopark WebCRM in turn translates these upload IDs to attachment IDs.
  #    Syntactically they look the same. Upload IDs, however, are only temporary,
  #    whereas attachment IDs are permanent. If the client appended a filename to the upload ID,
  #    the attachment ID will contain this filename, too. Otherwise, the attachment ID ends
  #    with <tt>"/file"</tt>. Please note that Infopark WebCRM replaces filename characters other
  #    than <tt>a-zA-Z0-9.+-</tt> with a dash. Multiple dashes will be joined into a single dash.
  # 4. Later, when downloading the attachment, pass the attachment ID to
  #    {Crm::Core::AttachmentStore.generate_download_url}.
  #    Infopark WebCRM returns a signed AWS S3 URL that remains valid for 5 minutes.
  # @api public
  class AttachmentStore
    # +Permission+ holds all the pieces of information required to upload an {AttachmentStore attachment}.
    # Generate a permission by calling {AttachmentStore.generate_upload_permission}.
    # @api public
    class Permission
      # Returns the {http://www.ruby-doc.org/stdlib/libdoc/uri/rdoc/URI.html URI}
      # for uploading the new attachment data.
      # @return [URI]
      # @api public
      attr_reader :uri

      # Returns the URL for uploading the new attachment data.
      # @return [String]
      # @api public
      attr_reader :url

      # Returns a hash of additional request parameters to be sent to the {#url}.
      # @return [Hash{String => String}]
      # @api public
      attr_reader :fields

      # Returns a temporary ID associated with this upload.
      # Use this ID when setting the +comment_attachments+ attribute of an activity.
      # @return [String]
      # @api public
      attr_reader :upload_id

      def initialize(uri, url, fields, upload_id)
        @uri, @url, @fields, @upload_id = uri, url, fields, upload_id
      end
    end

    class << self

      # Obtains the permission to upload a file manually.
      # The permission is valid for a couple of minutes.
      # Hence, it is recommended to have such permissions generated on demand.
      # @return [Permission]
      # @api public
      def generate_upload_permission
        perm = Core::RestApi.instance.post("attachment_store/generate_upload_permission", {})
        uri = resolve_uri(perm["url"])
        Permission.new(uri, uri.to_s, perm["fields"], perm["upload_id"])
      end

      # Generates a download URL for the given attachment.
      # The URL is valid for a couple of minutes.
      # Hence, it is recommended to have such URLs generated on demand.
      # @param attachment_id [String] the ID of an attachment.
      # @return [String]
      # @api public
      def generate_download_url(attachment_id)
        response = Core::RestApi.instance.post("attachment_store/generate_download_url",
            {'attachment_id' => attachment_id})
        resolve_uri(response["url"]).to_s
      end

      # Uploads a file to S3.
      # @param file [File] the file to be uploaded.
      # @return [String] the upload ID. Add this ID to the +comment_attachments+ attribute
      #   of an activity.
      def upload(file)
        permission = generate_upload_permission

        file_name = File.basename(file.path)
        upload_io = UploadIO.new(file, 'application/octet-stream', file_name)
        params = permission.fields.merge(file: upload_io)
        request = Net::HTTP::Post::Multipart.new(permission.uri, params)

        response = Core::ConnectionManager.new(permission.uri).request(request)

        if response.code.starts_with?('2')
          [permission.upload_id, file_name].compact.join('/')
        else
          raise Errors::ServerError, "File upload failed with code #{response.code}"
        end
      end

      private

      def resolve_uri(url)
        Core::RestApi.instance.resolve_uri(url)
      end
    end
  end
end; end
