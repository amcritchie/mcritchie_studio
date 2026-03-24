module Api
  module V1
    class AgentsController < BaseController
      def index
        agents = Agent.all.order(:name)
        render json: agents
      end

      def show
        agent = Agent.find_by!(slug: params[:slug])
        render json: agent.as_json(include: { skills: { only: [:name, :slug, :category] } })
      end

      def update
        agent = Agent.find_by!(slug: params[:slug])
        rescue_and_log(target: agent) do
          agent.update!(agent_params)
          render json: agent
        end
      rescue StandardError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def agent_params
        params.permit(:status, :description, :avatar_url, :title, config: {}, metadata: {})
      end
    end
  end
end
