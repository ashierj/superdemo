# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Audit::NamespaceSettingChangesAuditor, feature_category: :audit_events do
  using RSpec::Parameterized::TableSyntax

  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:destination) { create(:external_audit_event_destination, group: group) }

    subject(:auditor) { described_class.new(user, group.namespace_settings, group) }

    before do
      stub_licensed_features(extended_audit_events: true, external_audit_events: true)
    end

    shared_examples 'audited setting' do |attribute, event_name|
      before do
        group.namespace_settings.update!(attribute => prev_value)
      end

      it 'creates an audit event' do
        group.namespace_settings.update!(attribute => new_value)

        expect { auditor.execute }.to change { AuditEvent.count }.by(1)
        audit_details = {
          change: attribute,
          from: prev_value,
          to: new_value,
          target_details: group.full_path
        }
        expect(AuditEvent.last.details).to include(audit_details)
      end

      it 'streams correct audit event stream' do
        group.namespace_settings.update!(attribute => new_value)

        expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async).with(
          event_name, anything, anything)

        auditor.execute
      end

      context 'when attribute is not changed' do
        it 'does not create an audit event' do
          group.namespace_settings.update!(attribute => prev_value)

          expect { auditor.execute }.not_to change { AuditEvent.count }
        end
      end
    end

    context 'for boolean changes' do
      where(:prev_value, :new_value) do
        true | false
        false | true
      end

      with_them do
        context 'when ai-related settings are changed', :saas do
          let_it_be(:group) { create(:group_with_plan, plan: :ultimate_plan, trial_ends_on: Date.tomorrow) }
          let_it_be(:destination) { create(:external_audit_event_destination, group: group) }

          before do
            stub_licensed_features(
              ai_features: true,
              experimental_features: true,
              extended_audit_events: true,
              external_audit_events: true)
            stub_ee_application_setting(should_check_namespace_plan: true)
          end

          it_behaves_like 'audited setting', :experiment_features_enabled, 'experiment_features_enabled_updated'
          it_behaves_like 'audited setting', :duo_features_enabled, 'duo_features_enabled_updated'
        end
      end
    end
  end
end
