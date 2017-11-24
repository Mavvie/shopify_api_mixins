module ShopifyApiMixins
  module RetryOn5xx
    class << self
      attr_accessor :max_wait, :backoff_multiplier, :initial_wait
    end

    def request(*)
      with_retrial_on_5xx do
        super
      end
    end

    private

    def with_retrial_on_5xx
      retries = 0
      time_of_first_try = Time.now
      delay = RetryOn5xx.initial_wait

      loop do
        begin
          return yield
        rescue ActiveResource::ServerError => e
          if time_of_first_try < RetryOn5xx.max_wait.ago
            actual_wait_time = Time.now - time_of_first_try
            raise
          end
          code = e.response.code.to_i
          sleep(delay)
          retries += 1
          delay *= RetryOn5xx.backoff_multiplier
          next
        end
      end
    end
  end
end
