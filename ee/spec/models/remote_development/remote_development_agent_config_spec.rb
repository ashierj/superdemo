# frozen_string_literal: true

require 'spec_helper'

# noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31542
RSpec.describe RemoteDevelopment::RemoteDevelopmentAgentConfig, feature_category: :remote_development do
  # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31543
  let_it_be_with_reload(:agent) { create(:ee_cluster_agent, :with_remote_development_agent_config) }
  let(:default_default_resources_per_workspace_container) { {} }
  let(:default_max_resources_per_workspace) { {} }
  let(:default_network_policy_egress) do
    [
      {
        allow: "0.0.0.0/0",
        except: [
          - "10.0.0.0/8",
          - "172.16.0.0/12",
          - "192.168.0.0/16"
        ]
      }.deep_stringify_keys
    ]
  end

  subject(:config) { agent.remote_development_agent_config }

  describe 'associations' do
    it { is_expected.to belong_to(:agent) }
    it { is_expected.to have_many(:workspaces) }

    context 'with associated workspaces' do
      let(:workspace_1) { create(:workspace, agent: agent) }
      let(:workspace_2) { create(:workspace, agent: agent) }

      it 'has correct associations from factory' do
        expect(config.reload.workspaces).to contain_exactly(workspace_1, workspace_2)
        expect(workspace_1.remote_development_agent_config).to eq(config)
      end
    end
  end

  describe '#after_update' do
    it 'prevents dns_zone from being updated' do
      expect { config.update!(dns_zone: 'new-zone') }.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: Dns zone is currently immutable, and cannot be updated. Create a new agent instead."
      )
    end
  end

  describe 'validations' do
    context 'when config has an invalid dns_zone' do
      subject(:config) { build(:remote_development_agent_config, dns_zone: "invalid dns zone") }

      it 'prevents config from being created' do
        expect { config.save! }.to raise_error(
          ActiveRecord::RecordInvalid,
          "Validation failed: Dns zone contains invalid characters (valid characters: [a-z0-9\\-])"
        )
      end

      describe '#enabled' do
        it { is_expected.to validate_inclusion_of(:enabled).in_array([true, false]) }
      end
    end

    it 'when network_policy_egress is not specified explicitly' do
      expect(config).to be_valid
      expect(config.network_policy_egress).to eq(default_network_policy_egress)
    end

    it 'when network_policy_egress is nil' do
      config.network_policy_egress = nil
      expect(config).not_to be_valid
      expect(config.errors[:network_policy_egress]).to include(
        'must be a valid json schema',
        'must be an array'
      )
    end

    it 'when default_resources_per_workspace_container is not specified explicitly' do
      expect(config).to be_valid
      expect(config.default_resources_per_workspace_container).to eq(default_default_resources_per_workspace_container)
    end

    it 'when default_resources_per_workspace_container is nil' do
      config.default_resources_per_workspace_container = nil
      expect(config).not_to be_valid
      expect(config.errors[:default_resources_per_workspace_container]).to include(
        'must be a valid json schema',
        'must be a hash'
      )
    end

    it 'when max_resources_per_workspace is not specified explicitly' do
      expect(config).to be_valid
      expect(config.max_resources_per_workspace).to eq(default_max_resources_per_workspace)
    end

    it 'when default_resources_per_workspace_container is nil' do
      config.max_resources_per_workspace = nil
      expect(config).not_to be_valid
      expect(config.errors[:max_resources_per_workspace]).to include(
        'must be a valid json schema',
        'must be a hash'
      )
    end
  end
end
