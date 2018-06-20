module Crm
  # MailingRecipient represents a mailing recipient email address.
  # @api public
  class MailingRecipient < Core::BasicResource
    include Core::Mixins::Inspectable
    inspectable :id, :active, :consent, :topic_names

    # Returns the requested mailing recipient.
    # @example
    #   r = Crm::MailingRecipient.find("abc@example.com")
    #   r.active
    #   # => true
    #   r.consent
    #   # => "unknown"
    #   r.consent_given_at
    #   # => nil
    #   r.consent_revoked_at
    #   # => nil
    #   r.complained_at
    #   # => nil
    #   r.permanent_bounced_at
    #   # => nil
    #   r.topic_names
    #   # => ["foo"]
    #   r.topic_names_unsubscribed
    #   # => ["bar", "baz"]
    #   r.consent_logs
    #   # => [
    #     {
    #       "at"=>"2018-06-20T13:13:32Z",
    #       "description"=>"edited by API2 user root: this is the reason",
    #       "changes"=>{"active"=>["false", "true"]
    #     }
    #   ]
    # @param email [String] the email address
    # @return [MailingRecipient]
    # @api public
    def self.find(email)
      if email.blank?
        raise Crm::Errors::ResourceNotFound.new("Items could not be found.", [email])
      end
      new({'id' => email}).reload
    end

    # Updates the attributes of this mailing recipient.
    # @example
    #   mailing_recipient.update({
    #     consent: "given",
    #     topic_names: ["foo", "bar"],
    #     edit_reason: "user registered on www.example.com and confirmed the double opt-in email link",
    #   })
    #   mailing_recipient.update({
    #     consent: "revoked",
    #     edit_reason: "user unsubscribed using our newsletter form on www.example.com",
    #   })
    # @param attributes [Hash{String, Symbol => String}] the new attributes.
    # @return [self] the updated mailing recipient.
    # @api public
    def update(attributes = {})
      load_attributes(Core::RestApi.instance.put(path, attributes, if_match_header))
    end
  end
end
