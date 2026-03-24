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

      # Central error logging method — all API error logging flows through here.
      # Returns the ErrorLog record so callers can attach target/parent context.
      def create_error_log(exception)
        ErrorLog.capture!(exception)
      end

      def unprocessable(exception)
        create_error_log(exception)
        render json: { error: exception.message }, status: :unprocessable_entity
      end

      # Layer 2: Opt-in per-action wrapper with target/parent context.
      # Sets @_error_logged flag so Layer 1 won't double-log.
      def rescue_and_log(target: nil, parent: nil)
        yield
      rescue ActiveRecord::RecordNotFound => e
        raise e
      rescue StandardError => e
        error_log = create_error_log(e)
        if target
          error_log.target = target
          error_log.target_name = target.slug
        end
        if parent
          error_log.parent = parent
          error_log.parent_name = parent.slug
        end
        error_log.save!
        @_error_logged = true
        raise e
      end

      # Layer 1: Catch-all for unexpected errors — log + JSON 500.
      # Skips logging if rescue_and_log already captured it.
      def handle_unexpected_error(exception)
        create_error_log(exception) unless @_error_logged
        raise exception if Rails.env.development? || Rails.env.test?

        render json: { error: "Internal server error" }, status: :internal_server_error
      end
    end
  end
end
