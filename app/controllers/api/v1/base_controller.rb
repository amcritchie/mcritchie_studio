module Api
  module V1
    class BaseController < ActionController::API
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable
      rescue_from StandardError, with: :handle_unexpected_error

      private

      def not_found
        render json: { error: "Not found" }, status: :not_found
      end

      def unprocessable(exception)
        ErrorLog.capture!(exception)
        render json: { error: exception.message }, status: :unprocessable_entity
      end

      # Layer 2: Opt-in per-action wrapper with target/parent context.
      # Sets @_error_logged flag so Layer 1 won't double-log.
      def rescue_and_log(target: nil, parent: nil)
        yield
      rescue ActiveRecord::RecordNotFound => e
        raise e
      rescue StandardError => e
        ErrorLog.capture!(e, target: target, parent: parent)
        @_error_logged = true
        raise e
      end

      # Layer 1: Catch-all for unexpected errors — log + JSON 500.
      # Skips logging if rescue_and_log already captured it.
      def handle_unexpected_error(exception)
        ErrorLog.capture!(exception) unless @_error_logged
        raise exception if Rails.env.development? || Rails.env.test?

        render json: { error: "Internal server error" }, status: :internal_server_error
      end
    end
  end
end
