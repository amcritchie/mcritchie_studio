module Api
  module V1
    class BaseController < ActionController::API
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable

      private

      def not_found
        render json: { error: "Not found" }, status: :not_found
      end

      def unprocessable(exception)
        render json: { error: exception.message }, status: :unprocessable_entity
      end
    end
  end
end
