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
        agent.update!(agent_params)
        render json: agent
      end

      private

      def agent_params
        params.permit(:status, :description, :avatar_url, :title, config: {}, metadata: {})
      end
    end
  end
end
