module Crm
  # A JustRelate WebCRM collection is a saved search. To execute such a saved search, call {#compute}.
  # The results are persisted and can be accessed by means of {#output_items}.
  # Output items can be {Account accounts}, {Contact contacts}, {Activity activities},
  # and {Event events}.
  # @api public
  class Collection < Core::BasicResource
    include Core::Mixins::Findable
    include Core::Mixins::Modifiable
    include Core::Mixins::ChangeLoggable
    include Core::Mixins::Searchable
    include Core::Mixins::Inspectable
    inspectable :id, :title

    # @!parse extend Core::Mixins::Findable::ClassMethods
    # @!parse extend Core::Mixins::Modifiable::ClassMethods
    # @!parse extend Core::Mixins::Searchable::ClassMethods

    # Computes this collection.
    # @return [self]
    # @api public
    def compute
      load_attributes(Core::RestApi.instance.put("#{path}/compute", {}))
    end

    # Returns the IDs resulting from the computation.
    # @return [Array<String>]
    # @api public
    def output_ids
      Core::RestApi.instance.get("#{path}/output_ids")
    end

    # Returns an {Core::ItemEnumerator ItemEnumerator}
    # that provides access to the items of {#output_ids}.
    # @return [Core::ItemEnumerator]
    # @api public
    def output_items
      Core::ItemEnumerator.new(output_ids)
    end
  end
end
