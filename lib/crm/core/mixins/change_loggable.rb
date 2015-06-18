module Crm; module Core; module Mixins
  # +ChangeLoggable+ provides access to the change log of a resource.
  # A {ChangeLoggable::Change change log entry} contains the +before+ and +after+ values
  # of all attributes that were changed by an update.
  # It also includes the author (+changed_by+) and the timestamp (+changed_at+) of the change.
  # @example
  #   contact
  #   # => Crm::Contact
  #
  #   changes = contact.changes
  #   # => Array<ChangeLoggable::Change>
  #
  #   change = changes.first
  #   # => ChangeLoggable::Change
  #
  #   change.changed_by
  #   # => 'john_smith'
  #
  #   change.changed_at
  #   # => Time
  #
  #   change.details.keys
  #   # => ['email', 'locality']
  #
  #   detail = change.details[:email]
  #   # => ChangeLoggable::Change::Detail
  #
  #   detail.before
  #   # => old@example.com
  #
  #   detail.after
  #   # => new@example.com
  # @api public
  module ChangeLoggable
    # +Change+ represents a single change log entry contained in
    # {ChangeLoggable#changes item.changes}.
    # See {Crm::Core::Mixins::ChangeLoggable ChangeLoggable} for details.
    # @api public
    class Change
      include Core::Mixins::AttributeProvider

      def initialize(raw_change)
        change = raw_change.dup
        change['details'] = change['details'].each_with_object({}) do |(attr_name, detail), hash|
          hash[attr_name] = Detail.new(detail)
        end
        super(change)
      end

      # @!attribute [r] changed_at
      #   Returns the timestamp of the change to the item.
      #   @return [Time]
      #   @api public

      # @!attribute [r] changed_by
      #   Returns the login of the API user who made the change.
      #   @return [String]
      #   @api public

      # @!attribute [r] details
      #   Returns the details of the change
      #   (i.e. +before+ and +after+ of every changed attribute)
      #   @return [Array<Detail>]
      #   @api public

      # +Detail+ represents a single detail of a
      # {Crm::Core::Mixins::ChangeLoggable::Change change},
      # which can be accessed by means of {Change#details change.details}.
      # See {Crm::Core::Mixins::ChangeLoggable ChangeLoggable} for details.
      # @api public
      class Detail
        # @!attribute [r] before
        #   Returns the value before the change.
        #   @return [Object]
        #   @api public

        # @!attribute [r] after
        #   Returns the value after the change.
        #   @return [Object]
        #   @api public

        # flush yardoc!!!!
        include Core::Mixins::AttributeProvider
      end
    end

    # Returns the most recent changes made to this item.
    # @param limit [Fixnum] the number of changes to return at most.
    #   Maximum: +100+. Default: +10+.
    # @return [Array<Change>]
    # @api public
    def changes(limit: 10)
      RestApi.instance.get("#{path}/changes", {"limit" => limit})['results'].map do |change|
        Change.new(change)
      end
    end
  end
end; end; end
