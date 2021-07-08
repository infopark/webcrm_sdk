module Crm
  # A JustRelate WebCRM activity is a record of an action or a sequence of actions,
  # for example a support case.
  # It can be associated with an {Account account} or a {Contact contact}.
  #
  # === Comments
  # Comments can be read be means of {#comments}.
  # In order to add a comment, set the following write-only attributes on {.create} or {#update}:
  # * +comment_notes+ (String) - the comment text.
  # * +comment_contact_id+ (String) - the contact ID of the comment author (optional).
  # * +comment_published+ (Boolean) - whether the comment should be visible
  #   to the associated contact of this activity (+item.contact_id+).
  #   Default: +false+.
  # * +comment_attachments+ (Array<String, #read>) - the comment attachments (optional).
  #   Every array element may either be an attachment ID or an object that implements +#read+
  #   (e.g. an open file). In the latter case, the content will be
  #   uploaded automatically. See {Crm::Core::AttachmentStore} for manually uploading attachments.
  # @api public
  class Activity < Core::BasicResource
    include Core::Mixins::Findable
    include Core::Mixins::Modifiable
    include Core::Mixins::ChangeLoggable
    include Core::Mixins::Searchable
    include Core::Mixins::Inspectable
    inspectable :id, :title, :type_id

    # @!parse extend Core::Mixins::Findable::ClassMethods
    # @!parse extend Core::Mixins::Modifiable::ClassMethods
    # @!parse extend Core::Mixins::Searchable::ClassMethods

    # Creates a new activity using the given +params+.
    # See {Core::Mixins::Modifiable::ClassMethods#create Modifiable.create} for details.
    # @return [self] the created activity.
    # @api public
    def self.create(attributes = {})
      super(filter_attributes(attributes))
    end

    # Updates the attributes of this activity.
    # See {Core::Mixins::Modifiable#update Modifiable#update} for details.
    # @return [self] the updated activity.
    # @api public
    def update(attributes = {})
      super(self.class.filter_attributes(attributes))
    end

    # +Comment+ represents a comment of an {Activity Activity},
    # for example a single comment of a support case discussion.
    # @api public
    class Comment
      include Core::Mixins::AttributeProvider

      # +Attachment+ represents an attachment of an {Activity::Comment activity comment}.
      # @api public
      class Attachment
        # Returns the ID of this attachment.
        # @return [String]
        # @api public
        attr_reader :id

        def initialize(id)
          @id = id
        end

        # Generates a download URL for this attachment.
        # Retrieve the attachment data by fetching this URL.
        # This URL is only valid for a couple of minutes.
        # Hence, it is recommended to have such URLs generated on demand.
        # @return [String]
        # @api public
        def download_url
          Crm::Core::AttachmentStore.generate_download_url(id)
        end
      end

      def initialize(raw_comment)
        comment = raw_comment.dup
        comment['attachments'] = raw_comment['attachments'].map{ |attachment_id|
          Attachment.new(attachment_id)
        }
        super(comment)
      end

      # @!attribute [r] attachments
      #   Returns the list of comment {Attachment attachments}.
      #   @return [Array<Attachment>]
      #   @api public

      # @!attribute [r] updated_at
      #   Returns the timestamp of the comment.
      #   @return [Time]
      #   @api public

      # @!attribute [r] updated_by
      #   Returns the login of the API user who created the comment.
      #   @return [String]
      #   @api public

      # @!attribute [r] notes
      #   Returns the comment text.
      #   @return [String]
      #   @api public

      # @!attribute [r] published?
      # Returns whether the comment is published.
      # @return [Boolean]
      # @api public
      def published?
        published
      end
    end

    # @!attribute [r] comments
    # Returns the {Comment comments} of this activity.
    # @return [Array<Comment>]
    # @api public

    def self.filter_attributes(attributes)
      attachments = attributes.delete('comment_attachments') ||
          attributes.delete(:comment_attachments)
      if attachments
        attributes['comment_attachments'] = attachments.map do |attachment|
          if attachment.respond_to?(:read)
            Core::AttachmentStore.upload(attachment)
          else
            attachment
          end
        end
      end
      attributes
    end

    protected

    def load_attributes(raw_attributes)
      attributes = raw_attributes.dup
      attributes['comments'] = (attributes['comments'] || []).map do |comment_attributes|
        Comment.new(comment_attributes)
      end
      super(attributes)
    end
  end
end
