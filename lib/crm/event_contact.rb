module Crm
  # A JustRelate WebCRM event contact is a participant or a potential participant of an {Event}.
  # @api public
  class EventContact < Core::BasicResource
    include Core::Mixins::Findable
    include Core::Mixins::Modifiable
    include Core::Mixins::ChangeLoggable
    include Core::Mixins::Searchable
    include Core::Mixins::Inspectable
    inspectable :id

    # @!parse extend Core::Mixins::Findable::ClassMethods
    # @!parse extend Core::Mixins::Modifiable::ClassMethods
    # @!parse extend Core::Mixins::Searchable::ClassMethods
  end
end
