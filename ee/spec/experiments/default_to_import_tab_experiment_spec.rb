# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DefaultToImportTabExperiment, :experiment, feature_category: :acquisition do
  let(:objective) { 'move_repository' }

  let(:user) do
    build_stubbed(:user, user_detail: build_stubbed(:user_detail, registration_objective: objective))
  end

  it 'does not exclude the user' do
    expect(experiment(:default_to_import_tab)).not_to exclude(actor: user)
  end

  context 'when registration objective is not move_repository' do
    let(:objective) { 'code_storage' }

    it 'excludes the user' do
      expect(experiment(:default_to_import_tab)).to exclude(actor: user)
    end
  end

  context 'with candidate experience' do
    before do
      stub_experiments(default_to_import_tab: :candidate)
    end

    it 'registers the behavior' do
      expect(experiment(:default_to_import_tab, actor: user)).to register_behavior(:candidate).with(nil)
      expect { experiment(:default_to_import_tab, actor: user).run }.not_to raise_error
    end
  end

  context 'with control experience' do
    before do
      stub_experiments(default_to_import_tab: :control)
    end

    it 'registers the behavior' do
      expect(experiment(:default_to_import_tab, actor: user)).to register_behavior(:control).with(nil)
      expect { experiment(:default_to_import_tab, actor: user).run }.not_to raise_error
    end
  end
end
