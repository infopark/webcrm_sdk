require "active_support/concern"

module Crm; module Core; module Mixins
  # +Modifiable+ is a collection of methods that are used to {ClassMethods#create .create},
  # {#update}, {#delete}, and {#undelete} an Infopark WebCRM item.
  # @api public
  module Modifiable
    extend ActiveSupport::Concern

    # @api public
    module ClassMethods
      # Creates a new item using the given +attributes+.
      # @example
      #   Crm::Contact.create({
      #     language: 'en',
      #     last_name: 'Smith',
      #   })
      #   # => Crm::Contact
      # @param attributes [Hash{String, Symbol => String}] the attributes of the new item.
      # @return [BasicResource] the created item.
      # @raise [Errors::InvalidKeys] if +attributes+ contains unknown attribute names.
      # @raise [Errors::InvalidValues] if +attributes+ contains incorrect values.
      # @api public
      def create(attributes = {})
        new(RestApi.instance.post(path, attributes))
      end
    end
    # @!parse extend ClassMethods

    # Updates the attributes of this item.
    # @example
    #   contact.last_name
    #   # => 'Smith'
    #
    #   contact.locality
    #   # => 'New York'
    #
    #   contact.update({locality: 'Boston'})
    #   # => Crm::Contact
    #
    #   contact.last_name
    #   # => 'Smith'
    #
    #   contact.locality
    #   # => 'Boston'
    # @param attributes [Hash{String, Symbol => String}] the new attributes.
    # @return [self] the updated item.
    # @raise [Errors::InvalidKeys] if +attributes+ contains unknown attribute names.
    # @raise [Errors::InvalidValues] if +attributes+ contains incorrect values.
    # @raise [Errors::ResourceConflict] if the item has been changed concurrently.
    #   {Core::BasicResource#reload Reload} it, review the changes and retry.
    # @api public
    def update(attributes = {})
      load_attributes(RestApi.instance.put(path, attributes, if_match_header))
    end

    # Soft-deletes this item (i.e. marks it as deleted).
    #
    # The deleted item can be {#undelete undeleted}.
    # @example
    #   contact.deleted?
    #   # => false
    #
    #   contact.delete
    #   # => Crm::Contact
    #
    #   contact.deleted?
    #   # => true
    # @return [self] the deleted item.
    # @raise [Errors::ResourceConflict] if the item has been changed concurrently.
    #   {Core::BasicResource#reload Reload} it, review the changes and retry.
    # @api public
    def delete
      load_attributes(RestApi.instance.delete(path, nil, if_match_header))
    end

    # Undeletes this deleted item.
    # @example
    #   contact.deleted?
    #   # => true
    #
    #   contact.undelete
    #   # => Crm::Contact
    #
    #   contact.deleted?
    #   # => false
    # @return [self] the undeleted item.
    # @api public
    def undelete
      load_attributes(RestApi.instance.put("#{path}/undelete", {}))
    end

    # Returns +true+ if the item was deleted (i.e. +item.deleted_at+ is not empty).
    # @return [Boolean]
    # @api public
    def deleted?
      self['deleted_at'].present?
    end

    alias_method :destroy, :delete
  end
end; end; end
