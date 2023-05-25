# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReleasesFinder, feature_category: :release_orchestration do
  let_it_be(:user)  { create(:user) }
  let_it_be(:group) { create :group }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let(:params) { {} }
  let(:args) { {} }
  let(:repository) { project.repository }
  let_it_be(:v1_0_0)     { create(:release, project: project, tag: 'v1.0.0') }
  let_it_be(:v1_1_0)     { create(:release, project: project, tag: 'v1.1.0') }

  shared_examples_for 'when the user is not authorized' do
    it 'returns no releases' do
      is_expected.to be_empty
    end
  end

  shared_examples_for 'when a tag parameter is passed' do
    let(:params) { { tag: 'v1.0.0' } }

    it 'only returns the release with the matching tag' do
      expect(subject).to eq([v1_0_0])
    end
  end

  shared_examples_for 'preload' do
    it 'preloads associations' do
      expect(Release).to receive(:preloaded).once.and_call_original

      subject
    end

    context 'when preload is false' do
      let(:args) { { preload: false } }

      it 'does not preload associations' do
        expect(Release).not_to receive(:preloaded)

        subject
      end
    end
  end

  describe 'when parent is a project' do
    subject { described_class.new(project, user, params).execute(**args) }

    it_behaves_like 'when the user is not authorized'

    context 'when the user has guest privileges or higher' do
      before do
        project.add_guest(user)

        v1_0_0.update!(released_at: 2.days.ago, created_at: 1.day.ago)
        v1_1_0.update!(released_at: 1.day.ago, created_at: 2.days.ago)
      end

      it 'returns the releases' do
        is_expected.to be_present
        expect(subject.size).to eq(2)
        expect(subject).to match_array([v1_1_0, v1_0_0])
      end

      context 'with sorting parameters' do
        it 'sorted by released_at in descending order by default' do
          is_expected.to eq([v1_1_0, v1_0_0])
        end

        context 'released_at in ascending order' do
          let(:params) { { sort: 'asc' } }

          it { is_expected.to eq([v1_0_0, v1_1_0]) }
        end

        context 'order by created_at in descending order' do
          let(:params) { { order_by: 'created_at' } }

          it { is_expected.to eq([v1_0_0, v1_1_0]) }
        end

        context 'order by created_at in ascending order' do
          let(:params) { { order_by: 'created_at', sort: 'asc' } }

          it { is_expected.to eq([v1_1_0, v1_0_0]) }
        end
      end

      it_behaves_like 'preload'
      it_behaves_like 'when a tag parameter is passed'
    end
  end

  describe 'when parent is an array of projects' do
    let_it_be(:project2) { create(:project, :repository, group: group) }
    let_it_be(:v2_0_0) { create(:release, project: project2, tag: 'v2.0.0') }
    let_it_be(:v2_1_0) { create(:release, project: project2, tag: 'v2.1.0') }

    subject { described_class.new([project, project2], user, params).execute(**args) }

    it_behaves_like 'when the user is not authorized'

    context 'when the user has guest privileges or higher on one project' do
      before do
        project.add_guest(user)
      end

      it 'returns the releases of only the authorized project' do
        is_expected.to be_present
        expect(subject.size).to eq(2)
        expect(subject).to match_array([v1_1_0, v1_0_0])
      end
    end

    context 'when the user has guest privileges or higher on all projects' do
      before do
        project.add_guest(user)
        project2.add_guest(user)

        v1_0_0.update!(released_at: 4.days.ago, created_at: 1.day.ago)
        v1_1_0.update!(released_at: 3.days.ago, created_at: 2.days.ago)
        v2_0_0.update!(released_at: 2.days.ago, created_at: 3.days.ago)
        v2_1_0.update!(released_at: 1.day.ago,  created_at: 4.days.ago)
      end

      it 'returns the releases of all projects' do
        is_expected.to be_present
        expect(subject.size).to eq(4)
        expect(subject).to match_array([v2_1_0, v2_0_0, v1_1_0, v1_0_0])
      end

      it_behaves_like 'preload'
      it_behaves_like 'when a tag parameter is passed'

      context 'with sorting parameters' do
        it 'sorted by released_at in descending order by default' do
          is_expected.to eq([v2_1_0, v2_0_0, v1_1_0, v1_0_0])
        end

        context 'released_at in ascending order' do
          let(:params) { { sort: 'asc' } }

          it { is_expected.to eq([v1_0_0, v1_1_0, v2_0_0, v2_1_0]) }
        end

        context 'order by created_at in descending order' do
          let(:params) { { order_by: 'created_at' } }

          it { is_expected.to eq([v1_0_0, v1_1_0, v2_0_0, v2_1_0]) }
        end

        context 'order by created_at in ascending order' do
          let(:params) { { order_by: 'created_at', sort: 'asc' } }

          it { is_expected.to eq([v2_1_0, v2_0_0, v1_1_0, v1_0_0]) }
        end
      end
    end
  end
end
