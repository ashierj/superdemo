# frozen_string_literal: true

require 'spec_helper'

# noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31542
RSpec.describe RemoteDevelopment::Workspace, feature_category: :remote_development do
  let_it_be(:user) { create(:user) }
  let_it_be(:agent, reload: true) { create(:ee_cluster_agent, :with_remote_development_agent_config) }
  let_it_be(:project) { create(:project, :in_group) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }

  let(:desired_state) { ::RemoteDevelopment::Workspaces::States::STOPPED }

  subject(:workspace) do
    create(:workspace,
      user: user, agent: agent, project: project,
      personal_access_token: personal_access_token, desired_state: desired_state)
  end

  describe 'associations' do
    context "for has_one" do
      it { is_expected.to have_one(:remote_development_agent_config) }
    end

    context "for has_many" do
      it { is_expected.to have_many(:workspace_variables) }
    end

    context "for belongs_to" do
      it { is_expected.to belong_to(:user) }
      it { is_expected.to belong_to(:personal_access_token) }

      it do
        is_expected
          .to belong_to(:agent)
                .class_name('Clusters::Agent')
                .with_foreign_key(:cluster_agent_id)
                .inverse_of(:workspaces)
      end
    end

    context "when from factory" do
      it 'has correct associations from factory' do
        expect(workspace.user).to eq(user)
        expect(workspace.project).to eq(project)
        expect(workspace.agent).to eq(agent)
        expect(workspace.personal_access_token).to eq(personal_access_token)
        expect(workspace.remote_development_agent_config).to eq(agent.remote_development_agent_config)
        expect(agent.remote_development_agent_config.workspaces.first).to eq(workspace)
        expect(workspace.url).to eq("https://60001-#{workspace.name}.#{agent.remote_development_agent_config.dns_zone}")
      end
    end
  end

  describe '#terminated?' do
    let(:actual_state) { ::RemoteDevelopment::Workspaces::States::TERMINATED }

    subject(:workspace) { build(:workspace, actual_state: actual_state) }

    it 'returns true if terminated' do
      expect(workspace.terminated?).to eq(true)
    end
  end

  describe '.before_save' do
    describe 'when creating new record', :freeze_time do
      # NOTE: The workspaces factory overrides the desired_state_updated_at to be earlier than
      #       the current time, so we need to use build here instead of create here to test
      #       the callback which sets the desired_state_updated_at to current time upon creation.
      subject(:workspace) { build(:workspace, user: user, agent: agent, project: project) }

      it 'sets desired_state_updated_at' do
        workspace.save!
        expect(workspace.desired_state_updated_at).to eq(Time.current)
      end
    end

    describe 'when updating desired_state' do
      it 'sets desired_state_updated_at' do
        expect { workspace.update!(desired_state: ::RemoteDevelopment::Workspaces::States::RUNNING) }.to change {
          workspace.desired_state_updated_at
        }
      end
    end

    describe 'when updating a field other than desired_state' do
      it 'does not set desired_state_updated_at' do
        expect { workspace.update!(actual_state: ::RemoteDevelopment::Workspaces::States::RUNNING) }.not_to change {
          workspace.desired_state_updated_at
        }
      end
    end
  end

  describe 'validations' do
    it 'validates max_hours_before_termination is no more than 120' do
      workspace.max_hours_before_termination = described_class::MAX_HOURS_BEFORE_TERMINATION_LIMIT
      expect(workspace).to be_valid

      workspace.max_hours_before_termination = described_class::MAX_HOURS_BEFORE_TERMINATION_LIMIT + 1
      expect(workspace).not_to be_valid
    end

    it 'validates editor is webide' do
      workspace.editor = 'not-webide'
      expect(workspace).not_to be_valid
    end

    context 'on remote_development_agent_config' do
      context 'when no config is present' do
        let(:agent_with_no_remote_development_config) { create(:cluster_agent) }

        subject(:invalid_workspace) do
          build(:workspace, user: user, agent: agent_with_no_remote_development_config, project: project)
        end

        it 'validates presence of agent.remote_development_agent_config' do
          # sanity check of fixture
          expect(agent_with_no_remote_development_config.remote_development_agent_config).not_to be_present

          expect(invalid_workspace).not_to be_valid
          expect(invalid_workspace.errors[:agent])
            .to include('for Workspace must have an associated RemoteDevelopmentAgentConfig')
        end
      end

      context 'when a config is present' do
        subject(:workspace) do
          build(:workspace, user: user, agent: agent, project: project)
        end

        context 'when agent is enabled' do
          before do
            agent.remote_development_agent_config.enabled = true
          end

          it 'validates presence of agent.remote_development_agent_config' do
            expect(workspace).to be_valid
          end
        end

        context 'when agent is disabled' do
          before do
            agent.remote_development_agent_config.enabled = false
          end

          it 'validates presence of agent.remote_development_agent_config' do
            expect(workspace).not_to be_valid
            expect(workspace.errors[:agent])
              .to include("must have the 'enabled' flag set to true")
          end
        end
      end
    end

    context 'when desired_state is Terminated' do
      let(:desired_state) { ::RemoteDevelopment::Workspaces::States::TERMINATED }

      before do
        workspace.desired_state = ::RemoteDevelopment::Workspaces::States::STOPPED
      end

      it 'prevents changes to desired_state' do
        expect(workspace).not_to be_valid
        expect(workspace.errors[:desired_state])
          .to include("is 'Terminated', and cannot be updated. Create a new workspace instead.")
      end
    end
  end

  describe 'scopes' do
    describe '.without_terminated' do
      let(:actual_and_desired_state_running_workspace) do
        create(
          :workspace,
          actual_state: RemoteDevelopment::Workspaces::States::RUNNING,
          desired_state: RemoteDevelopment::Workspaces::States::RUNNING
        )
      end

      let(:desired_state_terminated_workspace) do
        create(:workspace, desired_state: RemoteDevelopment::Workspaces::States::TERMINATED)
      end

      let(:actual_state_terminated_workspace) do
        create(:workspace, actual_state: RemoteDevelopment::Workspaces::States::TERMINATED)
      end

      let(:actual_and_desired_state_terminated_workspace) do
        create(
          :workspace,
          actual_state: RemoteDevelopment::Workspaces::States::TERMINATED,
          desired_state: RemoteDevelopment::Workspaces::States::TERMINATED
        )
      end

      it 'returns workspaces who do not have desired_state and actual_state as Terminated' do
        workspace
        expect(described_class.without_terminated).to include(actual_and_desired_state_running_workspace)
        expect(described_class.without_terminated).to include(desired_state_terminated_workspace)
        expect(described_class.without_terminated).to include(actual_state_terminated_workspace)
        expect(described_class.without_terminated).not_to include(actual_and_desired_state_terminated_workspace)
      end
    end
  end
end
