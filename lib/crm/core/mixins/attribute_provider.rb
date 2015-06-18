module Crm; module Core; module Mixins
  # +AttributeProvider+ provides multiple ways to access the attributes of an item.
  # All attributes are available using {#[]}, {#attributes}
  # or a method named like the attribute.
  # @example
  #   contact
  #   # => Crm::Contact
  #
  #   contact.first_name
  #   # => "John"
  #
  #   contact['first_name']
  #   # => "John"
  #
  #   contact[:first_name]
  #   # => "John"
  #
  #   contact.unknown_attribute
  #   # => raises NoMethodError
  #
  #   contact['unknown_attribute']
  #   # => nil
  #
  #   contact.attributes
  #   # => {
  #   #  ...
  #   #  'first_name' => 'John',
  #   #  ...
  #   # }
  # @api public
  module AttributeProvider
    def initialize(attributes = nil)
      load_attributes(attributes || {})

      super()
    end

    # Makes all attributes accessible as methods.
    def method_missing(method_name, *args)
      return self[method_name] if has_attribute?(method_name)
      [
        "#{method_name}_id",
        "#{method_name.to_s.singularize}_ids",
      ].each do |id_name|
        return Crm.find(self[id_name]) if has_attribute?(id_name)
      end

      super
    end

    # Motivation see http://blog.marc-andre.ca/2010/11/15/methodmissing-politely/
    def respond_to_missing?(method_name, *)
      return true if has_attribute?(method_name)
      return true if has_attribute?("#{method_name}_id")
      return true if has_attribute?("#{method_name.to_s.singularize}_ids")

      super
    end

    def methods(*args)
      super | @extra_methods
    end

    # Returns the value associated with +attribute_name+.
    # Returns +nil+ if not found.
    # @example
    #   contact['first_name']
    #   # => "John"
    #
    #   contact[:first_name]
    #   # => "John"
    #
    #   contact['nonexistent']
    #   # => nil
    # @param attribute_name [String, Symbol]
    # @return [Object, nil]
    # @api public
    def [](attribute_name)
      @attrs[attribute_name.to_s]
    end

    # Returns the hash of all attribute names and their values.
    # @return [HashWithIndifferentAccess]
    # @api public
    def attributes
      @attrs
    end

    # Returns the value before type cast.
    # Returns +nil+ if attribute_name not found.
    # @example
    #   contact[:created_at]
    #   # => 2012-05-07 17:15:00 +0200
    #
    #   contact.raw(:created_at)
    #   # => "2012-05-07T15:15:00+00:00"
    # @return [Object, nil]
    # @api public
    def raw(attribute_name)
      @raw_attrs[attribute_name] || @attrs[attribute_name]
    end

    protected

    def load_attributes(attributes)
      @raw_attrs = HashWithIndifferentAccess.new
      @attrs = attributes.each_with_object(HashWithIndifferentAccess.new) do |(key, value), hash|
        if key.ends_with?('_at')
          @raw_attrs[key] = value
          value = begin
            Time.parse(value.to_s).in_time_zone
          rescue ArgumentError
            nil
          end
        end
        hash[key] = value
      end
      @extra_methods = []
      @attrs.keys.each do |key|
        key = key.to_s
        @extra_methods << key.to_sym
        @extra_methods << key.gsub(/_id$/, '').to_sym if key.ends_with?('_id')
        @extra_methods << key.gsub(/_ids$/, '').pluralize.to_sym if key.ends_with?('_ids')
      end
      @attrs.freeze
      self
    end

    private

    def has_attribute?(attribute_name)
      @attrs.has_key?(attribute_name.to_s)
    end
  end
end; end; end
