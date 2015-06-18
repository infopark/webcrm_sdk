module Crm
  # An Infopark WebCRM event contains all data associated with an event such
  # as a conference or a trade show. An event has participants ({EventContact}).
  # @api public
  class Event < Core::BasicResource
    include Core::Mixins::Findable
    include Core::Mixins::Modifiable
    include Core::Mixins::ChangeLoggable
    include Core::Mixins::Searchable
    include Core::Mixins::Inspectable
    inspectable :id, :title

    # @!parse extend Core::Mixins::Findable::ClassMethods
    # @!parse extend Core::Mixins::Modifiable::ClassMethods
    # @!parse extend Core::Mixins::Searchable::ClassMethods
  end
end
