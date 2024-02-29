# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::CiConfigurationService,
  feature_category: :security_policy_management do
  describe '#execute' do
    subject(:execute_service) { described_class.new.execute(action, ci_variables, context, index) }

    let(:action) { { scan: scan_type } }
    let(:ci_variables) { { KEY: 'value' } }
    let(:context) { 'context' }
    let(:index) { 0 }

    shared_examples_for 'a template scan' do
      it 'configures a template scan' do
        expect_next_instance_of(Security::SecurityOrchestrationPolicies::CiAction::Template,
          action,
          ci_variables,
          context,
          index
        ) do |instance|
          expect(instance).to receive(:config)
        end

        execute_service
      end
    end

    context 'with secret_detection scan action' do
      let(:scan_type) { 'secret_detection' }

      it_behaves_like 'a template scan'
    end

    context 'with container_scanning scan action' do
      let(:scan_type) { 'container_scanning' }

      it_behaves_like 'a template scan'
    end

    context 'with sast scan action' do
      let(:scan_type) { 'sast' }

      it_behaves_like 'a template scan'
    end

    context 'with sast_iac scan action' do
      let(:scan_type) { 'sast_iac' }

      it_behaves_like 'a template scan'
    end

    context 'with dependency_scanning scan action' do
      let(:scan_type) { 'dependency_scanning' }

      it_behaves_like 'a template scan'
    end

    context 'with custom scan action' do
      let(:scan_type) { 'custom' }

      it 'configures a custom scan' do
        expect_next_instance_of(Security::SecurityOrchestrationPolicies::CiAction::Custom,
          action,
          ci_variables,
          context,
          index
        ) do |instance|
          expect(instance).to receive(:config)
        end

        execute_service
      end
    end

    context 'with unknown action' do
      let(:scan_type) { anything }

      it 'configures a custom scan' do
        expect_next_instance_of(Security::SecurityOrchestrationPolicies::CiAction::Unknown,
          action,
          ci_variables,
          context,
          index
        ) do |instance|
          expect(instance).to receive(:config)
        end

        execute_service
      end
    end
  end
end
