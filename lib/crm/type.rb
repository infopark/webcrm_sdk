module Crm
  # A JustRelate WebCRM type defines a set of attributes associated with every instance of the type.
  # @example Listing all attributes of a type
  #   account_type = Crm::Type.find('account')
  #   # => Crm::Type
  #
  #   # Listing all standard attributes
  #   account_type.standard_attribute_definitions.keys
  #   # => ['name', 'created_at', 'updated_at', ...]
  #
  #   # Listing all custom attributes
  #   account_type.attribute_definitions.keys
  #   # => ['custom_plan', ...]
  #
  # @example Inspecting an attribute definition of a type
  #   account_type.standard_attribute_definitions["name"]
  #   # => {
  #   #  'attribute_type' => 'string',
  #   #  'create'         => true,
  #   #  'mandatory'      => true,
  #   #  'read'           => true,
  #   #  'title'          => 'Name',
  #   #  'update'         => true,
  #   # }
  #
  # @example Adding a new custom attribute to a type
  #   account_type.attribute_definitions.keys
  #   # => ['custom_plan']
  #
  #   # Add a new custom attribute named "custom_shipping_details"
  #   attr_defs = account_type.attribute_definitions.merge({
  #     custom_shipping_details: {
  #       attribute_type: 'text',
  #       title: 'Shipping Details',
  #     }
  #   })
  #   account_type.update({
  #     attribute_definitions: attr_defs,
  #   })
  #   # => Crm::Type
  #
  #   account_type.attribute_definitions.keys
  #   # => ['custom_plan', 'custom_shipping_details']
  #
  # @example Removing a custom attribute from a type
  #   account_type.attribute_definitions.keys
  #   # => ['custom_plan', 'custom_shipping_details']
  #
  #   attr_defs = account_type.attribute_definitions.except('custom_shipping_details')
  #   account_type.update({
  #     attribute_definitions: attr_defs,
  #   })
  #   # => Crm::Type
  #
  #   account_type.attribute_definitions.keys
  #   # => ['custom_plan']
  # @api public
  class Type < Core::BasicResource
    include Core::Mixins::Findable
    include Core::Mixins::Modifiable
    include Core::Mixins::ChangeLoggable
    include Core::Mixins::Inspectable
    inspectable :id, :item_base_type

    # @!parse extend Core::Mixins::Findable::ClassMethods
    # @!parse extend Core::Mixins::Modifiable::ClassMethods

    # Returns all types.
    # @return [Array<Type>]
    # @api public
    def self.all
      Core::RestApi.instance.get('types').map do |item|
        new(item)
      end
    end
  end
end
