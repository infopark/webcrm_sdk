module Crm; module Core
  # +ItemEnumerator+ provides methods for accessing items identified by their ID.
  # It implements {#each} and includes the
  # {http://ruby-doc.org/core/Enumerable.html Enumerable} mixin,
  # which provides methods such as +#map+, +#select+ or +#take+.
  # @api public
  class ItemEnumerator
    include Enumerable
    include Core::Mixins::Inspectable
    inspectable :length, :total

    # Returns the IDs of the items to enumerate.
    # @return [Array<String>]
    # @api public
    attr_reader :ids

    # If the ItemEnumerator is the result of a search, it returns the total number of search hits.
    # Otherwise, it returns {#length}.
    # @return [Fixnum]
    # @api public
    attr_reader :total

    def initialize(ids, total: nil)
      @ids = ids
      @total = total || ids.length
    end

    # Iterates over the {#ids} and fetches the corresponding items on demand.
    # @overload each
    #   Calls the block once for each item, passing this item as a parameter.
    #   @yieldparam item [BasicResource]
    #   @return [void]
    # @overload each
    #   If no block is given, an {http://ruby-doc.org/core/Enumerator.html enumerator}
    #   is returned instead.
    #   @return [Enumerator<BasicResource>]
    # @raise [Errors::ResourceNotFound] if at least one of the IDs could not be found.
    # @api public
    def each(&block)
      return enum_for(:each) unless block_given?

      server_limit = 100
      @ids.each_slice(server_limit) do |sliced_ids|
        RestApi.instance.get('mget', {'ids' => sliced_ids}).map do |item|
          block.call "Crm::#{item['base_type']}".constantize.new(item)
        end
      end
    end

    # Returns the number of items.
    # Prefer this method over +Enumerable#count+
    # because +#length+ doesn't fetch the items and therefore is faster than +Enumerable#count+.
    # @return [Fixnum]
    # @api public
    def length
      @ids.length
    end

    alias_method :size, :length
  end
end; end
