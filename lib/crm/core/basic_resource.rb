module Crm; module Core
  # +BasicResource+ is the base class of all Infopark WebCRM SDK resources.
  # @api public
  class BasicResource
    include Mixins::AttributeProvider

    def self.base_type
      name.split(/::/).last
    end

    def self.resource_name
      base_type.underscore
    end

    def self.path
      resource_name.pluralize
    end

    # Returns the ID of this item.
    # @return [String]
    # @api public
    def id
      self['id']
    end

    def path
      [self.class.path, id].compact.join('/')
    end

    # Returns the type object of this item.
    # @return [Crm::Type]
    # @api public
    def type
      ::Crm::Type.find(type_id)
    end

    # Reloads the attributes of this item from the remote web service.
    # @example
    #   contact.locality
    #   # => 'Bergen'
    #
    #   # Assume this contact has been modified concurrently.
    #
    #   contact.reload
    #   # => Crm::Contact
    #
    #   contact.locality
    #   # => 'Oslo'
    # @return [self] the reloaded item.
    # @api public
    def reload
      load_attributes(RestApi.instance.get(path))
    end

    def eql?(other)
      other.equal?(self) || other.instance_of?(self.class) && other.id == id
    end

    alias_method :==, :eql?
    delegate :hash, to: :id

    private

    def if_match_header
      {'If-Match' => self['version']}
    end
  end
end; end
