# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::UpdateProjectAndNamespaceUsageWorker do
  let_it_be(:project) { create(:project) }
  let_it_be(:namespace) { project.namespace }
  let_it_be(:build) { create(:ci_build, project: project) }

  let(:consumption) { 100 }
  let(:consumption_seconds) { consumption * 60 }
  let(:worker) { described_class.new }

  describe '#perform', :clean_gitlab_redis_shared_state do
    subject { perform_multiple([consumption, project.id, namespace.id, build.id]) }

    context 'behaves idempotently for monthly usage update' do
      it 'executes UpdateProjectAndNamespaceUsageService' do
        service_instance = double
        expect(::Ci::Minutes::UpdateProjectAndNamespaceUsageService).to receive(:new).at_least(:once).and_return(service_instance)
        expect(service_instance).to receive(:execute).at_least(:once).with(consumption)

        subject
      end

      it 'updates monthly usage' do
        subject

        expect(Ci::Minutes::NamespaceMonthlyUsage.find_by(namespace: namespace).amount_used).to eq(consumption)
        expect(Ci::Minutes::ProjectMonthlyUsage.find_by(project: project).amount_used).to eq(consumption)
      end
    end

    it 'does not behave idempotently for legacy statistics update' do
      expect(::Ci::Minutes::UpdateProjectAndNamespaceUsageService).to receive(:new).twice.and_call_original

      subject

      expect(project.statistics.reload.shared_runners_seconds).to eq(2 * consumption_seconds)
      expect(namespace.reload.namespace_statistics.shared_runners_seconds).to eq(2 * consumption_seconds)
    end
  end
end
