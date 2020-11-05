module Crm
  # MailingDelivery represents a mailing delivery.
  # @api public
  class MailingDelivery
    include Core::Mixins::Inspectable
    include Core::Mixins::AttributeProvider

    inspectable :mailing_id, :id

    def self.all(mailing_id, since: nil)
      path = ['mailings', mailing_id, 'mailing_deliveries'].compact.join('/')
      params = {}
      case since
      when Time
        params[:since] = since.utc.xmlschema
      when String
        params[:since] = since
      when nil
        # ignore
      else
        raise "unknown class of since param: #{since.class}"
      end
      Core::RestApi.instance.get(path, params).map {|attrs| new({'mailing_id' => mailing_id}.merge(attrs))}
    end

    # Creates or updates a mailing delivery.
    # @example
    #   Crm::MailingDelivery.create(mailing.id, "abc@example.com", {
    #     custom_data: {
    #       salutation: 'Hello You',
    #     },
    #   })
    # @param mailing_id [String] the mailing ID
    # @param id [String] the email address
    # @param attributes [Hash{String, Symbol => String}] the new attributes.
    # @return [self] the created or updated mailing delivery.
    # @api public
    def self.create(mailing_id, id, attributes = {})
      new({'mailing_id' => mailing_id, 'id' => id}).update(attributes)
    end

    # Returns the requested mailing delivery.
    # @example
    #   d = Crm::MailingDelivery.find(mailing.id, "abc@example.com")
    #   # => #<Crm::MailingDelivery mailing_id="94933088cec0014575ff920ee9830cfb", id="abc@example.com">
    # @param mailing_id [String] the mailing ID
    # @param id [String] the email address
    # @return [MailingDelivery]
    # @api public
    def self.find(mailing_id, id)
      raise Crm::Errors::ResourceNotFound.new("Items could not be found.", [mailing_id]) if mailing_id.blank?
      raise Crm::Errors::ResourceNotFound.new("Items could not be found.", [id]) if id.blank?

      new({'mailing_id' => mailing_id, 'id' => id}).reload
    end

    # Deletes the mailing delivery.
    #
    # @raise [Errors::ResourceConflict] if the item has been changed concurrently.
    #   {Core::BasicResource#reload Reload} it, review the changes and retry.
    # @api public
    def delete
      Core::RestApi.instance.delete(path, nil, if_match_header)
      nil
    end

    # Updates the attributes of this mailing delivery.
    # @example
    #   mailing_delivery.update({
    #     custom_data: {
    #       salutation: 'Hello You',
    #     },
    #   })
    # @param attributes [Hash{String, Symbol => String}] the new attributes.
    # @return [self] the updated mailing delivery.
    # @api public
    def update(attributes = {})
      load_attributes(Core::RestApi.instance.put(path, attributes, if_match_header))
    end

    def reload
      load_attributes(Core::RestApi.instance.get(path))
    end

    private

    def path
      ['mailings', mailing_id, 'mailing_deliveries', id].compact.join('/')
    end

    def if_match_header
      {'If-Match' => self['version']}
    end
  end
end
