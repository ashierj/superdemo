# frozen_string_literal: true

require 'fast_spec_helper'
require './keeps/helpers/milestones'

RSpec.describe Keeps::Helpers::Milestones, feature_category: :tooling do
  before do
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with(File.expand_path('../../../VERSION', __dir__)).and_return('16.9.0-pre')
  end

  describe '#before_cuttoff?' do
    let(:milestone) { '16.9' }

    subject(:before_cuttoff) { described_class.new.before_cuttoff?(milestone: milestone, milestones_ago: 12) }

    it { is_expected.to eq(false) }

    context 'when milestone is before cuttoff' do
      let(:milestone) { '15.9' }

      it { is_expected.to eq(true) }
    end

    context 'when milestone is more than 2 major versions before cuttoff' do
      let(:milestone) { '14.12' }

      it { is_expected.to eq(true) }
    end
  end
end
