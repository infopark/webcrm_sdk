module Crm
  # @api public
  module Errors
    # +BaseError+ is the superclass of all Infopark WebCRM SDK errors.
    # @api public
    class BaseError < StandardError
    end

    # +ServerError+ is raised if an internal error occurs in the API server.
    # @api public
    class ServerError < BaseError
    end

    # +ClientError+ is the superclass of all errors that are a result of client-supplied input.
    # @api public
    class ClientError < BaseError
    end

    # +UnauthorizedAccess+ is raised if the API user credentials are invalid.
    # Set the correct API user credentials using {Crm.configure}.
    # @api public
    class UnauthorizedAccess < ClientError
    end

    # +AuthenticationFailed+ is raised if the credentials used with
    # {Crm::Contact.authenticate!} are invalid.
    # @api public
    class AuthenticationFailed < ClientError
    end

    # +ForbiddenAccess+ is raised if the API user is not permitted to access the resource.
    # @api public
    class ForbiddenAccess < ClientError
    end

    # +TooManyParams+ is raised if more than 1000 keys are passed as parameters to
    # {Core::Mixins::Modifiable::ClassMethods#create Modifiable.create} or
    # {Core::Mixins::Modifiable#update Modifiable#update}.
    # @api public
    class TooManyParams < ClientError
    end

    # +ResourceNotFound+ is raised if the requested IDs could not be found.
    # @api public
    class ResourceNotFound < ClientError
      # Returns the IDs that could not be found.
      # @return [Array<String>]
      # @example
      #   ["9762b2b4382f6bf34adbdeb21ce588aa"]
      # @api public
      attr_reader :missing_ids

      def initialize(message = nil, missing_ids = [])
        super("#{message} Missing IDs: #{missing_ids.to_sentence}")

        @missing_ids = missing_ids
      end
    end

    # +ItemStatePreconditionFailed+ is raised if one or more preconditions
    # for the attempted action were not satisfied. For example, a deleted item cannot be updated.
    # It must be undeleted first.
    # @api public
    class ItemStatePreconditionFailed < ClientError
      # Returns the unmet preconditions.
      # The items in the list are hashes consisting of a +code+ (the name of the precondition),
      # and an English translation (+message+).
      # @return [Array<Hash{String => String}>]
      # @example
      #   [
      #     {
      #       "code" => "is_internal_mailing",
      #       "message" => "The mailing is not an internal mailing.",
      #     },
      #   ]
      # @api public
      attr_reader :unmet_preconditions

      def initialize(message = nil, unmet_preconditions)
        precondition_messages = unmet_preconditions.map{ |p| p['message'] }
        new_message = ([message] + precondition_messages).join(' ')
        super(new_message)

        @unmet_preconditions = unmet_preconditions
      end
    end

    # +ResourceConflict+ is raised if the item has been changed concurrently.
    # {Core::BasicResource#reload Reload} the item, review the changes and retry.
    # @api public
    class ResourceConflict < ClientError
    end

    # +InvalidKeys+ is raised if a create or update request contains unknown attributes.
    # @api public
    class InvalidKeys < ClientError
      # Returns the list of validation errors.
      # The items in the list are hashes consisting of a +code+ (always +unknown+),
      # the invalid +attribute+ name and an English translation (+message+).
      # @return [Array<Hash{String => String}>]
      # @example
      #   [
      #     {
      #       "attribute" => "foo",
      #       "code" => "unknown",
      #       "message" => "foo is unknown",
      #     },
      #   ]
      # @api public
      attr_reader :validation_errors

      def initialize(message = nil, validation_errors = {})
        super("#{message} #{validation_errors.map{ |h| h['message'] }.to_sentence}.")

        @validation_errors = validation_errors
      end
    end

    # +InvalidValues+ is raised if the keys of a create or update request are recognized
    # but include incorrect values.
    # @api public
    class InvalidValues < ClientError
      # Returns the list of validation errors.
      # The items in the list are hashes consisting of a +code+ (the name of the validation error,
      # i.e. one of the rails validation error codes),
      # an +attribute+ name and an English translation (+message+).
      # You may use +code+ to translate the message into other languages.
      # @example
      #   [
      #     {
      #       "code" => "blank",
      #       "attribute" => "name",
      #       "message" => "name is blank",
      #     },
      #   ]
      # @return [Array<Hash{String => String}>]
      # @api public
      attr_reader :validation_errors

      def initialize(message = nil, validation_errors = {})
        super("#{message} #{validation_errors.map{ |h| h['message'] }.to_sentence}.")

        @validation_errors = validation_errors
      end
    end

    # +RateLimitExceeded+ is raised if too many requests were issued within a given time frame.
    # @api public
    class RateLimitExceeded < ClientError
    end

    # +NetworkError+ is raised if a non-recoverable network-related error occurred
    # (e.g. connection timeout).
    # @api public
    class NetworkError < BaseError
      # Returns the underlying network error.
      # E.g. {http://www.ruby-doc.org/stdlib/libdoc/timeout/rdoc/Timeout/Error.html Timeout::Error}
      # @return [Exception]
      # @api public
      attr_reader :cause

      def initialize(message = nil, cause = nil)
        super(message)

        @cause = cause
      end
    end
  end
end
