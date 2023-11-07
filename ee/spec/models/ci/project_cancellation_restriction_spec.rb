# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ProjectCancellationRestriction, feature_category: :continuous_integration do
  let(:project) { create_default(:project) }
  let(:cancellation_restriction) { described_class.new(project) }
  let(:settings) { project.ci_cd_settings }
  let(:roles) { settings.class.restrict_pipeline_cancellation_roles }

  describe '#maintainers_only_allowed?' do
    context 'when cancellation restrictions are enabled' do
      before do
        stub_enabled
      end

      it 'returns true if maintainers are the only ones allowed to cancel' do
        settings.update!(restrict_pipeline_cancellation_role: roles[:maintainer])

        expect(cancellation_restriction.maintainers_only_allowed?).to be_truthy
      end

      [:no_one, :developer].each do |role|
        it "returns false if #{role} is allowed to cancel" do
          settings.update!(restrict_pipeline_cancellation_role: role)

          expect(cancellation_restriction.maintainers_only_allowed?).to be_falsy
        end
      end
    end

    context 'when cancellation restrictions are disabled' do
      before do
        stub_disabled
      end

      it 'returns false' do
        expect(cancellation_restriction.maintainers_only_allowed?).to be_falsy
      end
    end
  end

  describe '#no_one_allowed?' do
    context 'when cancellation restrictions are enabled' do
      before do
        stub_enabled
      end

      it 'returns true if no one is allowed to cancel' do
        settings.update!(restrict_pipeline_cancellation_role: roles[:no_one])

        expect(cancellation_restriction.no_one_allowed?).to be_truthy
      end

      [:maintainer, :developer].each do |role|
        it "returns false if #{role} is allowed to cancel" do
          settings.update!(restrict_pipeline_cancellation_role: role)

          expect(cancellation_restriction.no_one_allowed?).to be_falsy
        end
      end
    end

    context 'when cancellation restrictions are disabled' do
      before do
        stub_disabled
      end

      it 'returns false' do
        expect(cancellation_restriction.no_one_allowed?).to be_falsy
      end
    end
  end

  describe '#enabled?' do
    context 'when the feature is enabled and licensed' do
      before do
        stub_enabled
      end

      it 'returns true' do
        expect(cancellation_restriction.enabled?).to be_truthy
      end
    end

    context 'when the feature is disabled' do
      before do
        stub_feature_flags(restrict_pipeline_cancellation_by_role: false)
        stub_licensed_features(ci_pipeline_cancellation_restrictions: true)
      end

      it 'returns false' do
        expect(cancellation_restriction.enabled?).to be_falsy
      end
    end

    context 'when the feature is enabled but not licensed' do
      before do
        stub_licensed_features(ci_pipeline_cancellation_restrictions: false)
      end

      it 'returns false' do
        expect(cancellation_restriction.enabled?).to be_falsy
      end
    end

    context 'when the feature is disabled and not licensed' do
      before do
        stub_disabled
      end

      it 'returns false' do
        expect(cancellation_restriction.enabled?).to be_falsy
      end
    end
  end

  def stub_enabled
    stub_licensed_features(ci_pipeline_cancellation_restrictions: true)
  end

  def stub_disabled
    stub_feature_flags(restrict_pipeline_cancellation_by_role: false)
    stub_licensed_features(ci_pipeline_cancellation_restrictions: false)
  end
end
