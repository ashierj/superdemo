# frozen_string_literal: true

module Ai
  module Agents
    class CreateAgentService < BaseService
      def initialize(project, name, prompt)
        @project = project
        @name = name
        @prompt = prompt
      end

      def execute
        @agent = Ai::Agent.new(
          project: @project,
          name: @name
        )

        @agent.save

        Ai::Agents::CreateAgentVersionService.new(@agent, @prompt).execute if @agent.persisted?

        @agent
      end
    end
  end
end
