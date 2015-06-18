module Crm; module Core; module Mixins
  # +Findable+ lets you fetch an item using {ClassMethods#find .find}.
  # @example
  #   Crm::Contact.find('e70a7123f499c5e0e9972ab4dbfb8fe3')
  #   # => Crm::Contact
  # @api public
  module Findable
    extend ActiveSupport::Concern

    # @api public
    module ClassMethods
      # Returns the requested item.
      # @param id [String] the ID of the item.
      # @return [BasicResource]
      # @raise [Errors::ResourceNotFound]
      #   if the ID could not be found or the base type did not match.
      # @api public
      def find(id)
        if id.blank?
          raise Crm::Errors::ResourceNotFound.new(
              "Items could not be found.", [id])
        end
        new({'id' => id}).reload
      end
    end
    # @!parse extend ClassMethods
  end
end; end; end
