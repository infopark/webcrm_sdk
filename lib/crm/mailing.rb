module Crm
  # The purpose of an Infopark WebCRM mailing is to send an e-mail, e.g. a newsletter,
  # to several recipients.
  # The e-mails will be sent to the members of the contact collection associated with the mailing
  # (+mailing.collection_id+).
  #
  # Infopark WebCRM uses the {http://liquidmarkup.org/ Liquid template engine} for evaluating
  # mailing content.
  # @api public
  class Mailing < Core::BasicResource
    include Core::Mixins::Findable
    include Core::Mixins::Modifiable
    include Core::Mixins::ChangeLoggable
    include Core::Mixins::Searchable
    include Core::Mixins::Inspectable
    inspectable :id, :title

    # @!parse extend Core::Mixins::Findable::ClassMethods
    # @!parse extend Core::Mixins::Modifiable::ClassMethods
    # @!parse extend Core::Mixins::Searchable::ClassMethods

    # Renders a preview of the e-mail for the given contact.
    # @example
    #   mailing.html_body
    #   # => "<h1>Welcome {{contact.first_name}} {{contact.last_name}}</h1>"
    #
    #   contact.email
    #   # => "john.doe@example.com"
    #
    #   mailing.render_preview(contact)
    #   # => {
    #   #  "email_from" => "Marketing <marketing@example.org>",
    #   #  "email_reply_to" => "marketing-replyto@example.com",
    #   #  "email_subject" => "Invitation to exhibition",
    #   #  "email_to" => "john.doe@example.com",
    #   #  "text_body" => "Welcome John Doe",
    #   #  "html_body" => "<h1>Welcome John Doe</h1>"
    #   # }
    # @param render_for_contact_or_id [String, Contact]
    #   the contact for which the e-mail preview is rendered.
    # @return [Hash{String => String}] the values of the mailing fields evaluated
    #   in the context of the contact.
    # @api public
    def render_preview(render_for_contact_or_id)
      Core::RestApi.instance.post("#{path}/render_preview", {
        'render_for_contact_id' => extract_id(render_for_contact_or_id)
      })
    end

    # Sends a proof e-mail (personalized for a contact) to the current user (the API user).
    # @example
    #   mailing.send_me_a_proof_email(contact)
    #   # => {
    #   #   "message" => "e-mail sent to api_user@example.com"
    #   # }
    # @param render_for_contact_or_id [String, Contact]
    #   the contact for which the proof e-mail is rendered.
    # @return [Hash{String => String}] a status report.
    # @api public
    def send_me_a_proof_email(render_for_contact_or_id)
      Core::RestApi.instance.post("#{path}/send_me_a_proof_email", {
        'render_for_contact_id' => extract_id(render_for_contact_or_id)
      })
    end

    # Sends this mailing to a single contact.
    #
    # Use case: If someone registers for a newsletter, you can send them the most recent issue
    # that has already been released.
    # @example
    #   contact.email
    #   # => "john.doe@example.org"
    #
    #   mailing.released_at
    #   # => 2014-12-01 12:48:00 +0100
    #
    #   mailing.send_single_email(contact)
    #   # => {
    #   #   "message" => "e-mail sent to john.doe@example.org"
    #   # }
    # @param recipient_contact_or_id [String, Contact]
    #   the contact to send a single e-mail to.
    # @return [Hash{String => String}] a status report.
    # @api public
    def send_single_email(recipient_contact_or_id)
      Core::RestApi.instance.post("#{path}/send_single_email", {
        'recipient_contact_id' => extract_id(recipient_contact_or_id)
      })
    end

    # Releases this mailing.
    #
    # Sends the mailing to all recipients, marks the mailing as
    # released (+released_at+, +released_by+), and also sets +planned_release_at+ to now.
    # @return [self] the updated mailing.
    # @api public
    def release
      load_attributes(Core::RestApi.instance.post("#{path}/release", {}))
    end

    private

    def extract_id(contact_or_id)
      if contact_or_id.respond_to?(:id)
        contact_or_id.id
      else
        contact_or_id
      end
    end
  end
end
