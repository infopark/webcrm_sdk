module Crm; module Core; module Mixins
  # +MergeAndDeletable+ provides the common {#merge_and_delete} method
  # for {Account accounts} and {Contact contacts}.
  # @api public
  module MergeAndDeletable
    # Assigns the items associated with this item to the account or contact
    # whose ID is +merge_into_id+. Afterwards, the current item is deleted.
    # @param merge_into_id [String]
    #   the ID of the account or contact to which the associated items are assigned.
    # @api public
    def merge_and_delete(merge_into_id)
      RestApi.instance.post("#{path}/merge_and_delete", {"merge_into_id" => merge_into_id})
      nil
    end
  end
end; end; end
