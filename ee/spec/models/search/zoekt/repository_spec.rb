# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::Zoekt::Repository, feature_category: :global_search do
  subject { create(:zoekt_repository) }

  describe 'relations' do
    it { is_expected.to belong_to(:zoekt_index).inverse_of(:zoekt_repositories) }
    it { is_expected.to belong_to(:project).inverse_of(:zoekt_repository) }
  end

  describe 'before_validation' do
    let(:zoekt_repository) { create(:zoekt_repository) }

    it 'sets project_identifier equal to project_id' do
      zoekt_repo = create(:zoekt_repository, project_identifier: "")
      zoekt_repo.valid?
      expect(zoekt_repo.project_identifier).to eq zoekt_repo.project_id
    end
  end

  describe 'validation' do
    let(:zoekt_repository) { create(:zoekt_repository) }

    it 'validates project_id and project_identifier' do
      expect { zoekt_repository.project_id = 'invalid_id' }.to change { zoekt_repository.valid? }.to false
    end

    it 'validated uniqueness on zoekt_index_id and project_id' do
      project = create(:project)
      zoekt_index = create(:zoekt_index)
      zoekt_repo = create(:zoekt_repository, project: project, zoekt_index: zoekt_index)
      expect(zoekt_repo.valid?).to be_truthy
      zoekt_repo1 = build(:zoekt_repository, project: project, zoekt_index: zoekt_index)

      expect(zoekt_repo1.valid?).to be_falsey
    end
  end
end
