module Patience
  DEFAULT_SLEEP   = 0.25
  DEFAULT_TIMEOUT = 120

  NotifyTimeout = Class.new(Timeout::Error)
  TimeoutError  = Class.new(Interrupt)

  #
  # Executes given block for a certain time.
  #
  # If the block execution does not terminate in time, a timeout exception is raised.
  # If the block raises an error, it is re-executed.
  # If the block (finally) executes without error, the block's result is returned.
  # Otherwise the last execution error is raised.
  #
  def self.try(options={})
    options = options.reverse_merge(timeout: DEFAULT_TIMEOUT, sleep: DEFAULT_SLEEP)

    result = nil
    last_execution_error = nil

    Timeout::timeout(options[:timeout], Patience::NotifyTimeout) do
      begin
        result = yield
      rescue NameError, NoMethodError, SyntaxError, TypeError
        raise
      rescue Patience::NotifyTimeout => unfinished_execution
        raise last_execution_error if last_execution_error
        raise Patience::TimeoutError,
            "#{unfinished_execution.message}\n#{unfinished_execution.backtrace.join("\n")}"
      rescue Exception => last_execution_error
        sleep(options[:sleep])
        retry
      end
    end

    result
  end
end
