module Crm
  # An Infopark WebCRM account is an organizational entity such as a company.
  # @api public
  class Account < Core::BasicResource
    include Core::Mixins::Findable
    include Core::Mixins::Modifiable
    include Core::Mixins::ChangeLoggable
    include Core::Mixins::MergeAndDeletable
    include Core::Mixins::Searchable
    include Core::Mixins::Inspectable
    inspectable :id, :name

    # @!parse extend Core::Mixins::Findable::ClassMethods
    # @!parse extend Core::Mixins::Modifiable::ClassMethods
    # @!parse extend Core::Mixins::Searchable::ClassMethods
  end
end
