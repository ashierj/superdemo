# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admin::AbuseReportEntity, feature_category: :insider_threat do
  include Gitlab::Routing

  let(:abuse_report) { build_stubbed(:abuse_report) }

  let(:entity) do
    described_class.new(abuse_report)
  end

  describe '#as_json' do
    subject(:entity_hash) { entity.as_json }

    it 'exposes correct attributes' do
      expect(entity_hash.keys).to include(
        :category,
        :updated_at,
        :reported_user,
        :reporter,
        :reported_user_path,
        :reporter_path
      )
    end

    it 'correctly exposes `reported user`' do
      expect(entity_hash[:reported_user].keys).to match_array([:name])
    end

    it 'correctly exposes `reporter`' do
      expect(entity_hash[:reporter].keys).to match_array([:name])
    end

    it 'correctly exposes :reported_user_path' do
      expect(entity_hash[:reported_user_path]).to eq user_path(abuse_report.user)
    end

    it 'correctly exposes :reporter_path' do
      expect(entity_hash[:reporter_path]).to eq user_path(abuse_report.reporter)
    end
  end
end
