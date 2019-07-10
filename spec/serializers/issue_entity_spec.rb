require 'spec_helper'

describe IssueEntity do
  let(:project)  { create(:project) }
  let(:resource) { create(:issue, project: project) }
  let(:user)     { create(:user) }

  let(:request) { double('request', current_user: user) }

  subject { described_class.new(resource, request: request).as_json }

  it 'has Issuable attributes' do
    expect(subject).to include(:id, :iid, :author_id, :description, :lock_version, :milestone_id,
                               :title, :updated_by_id, :created_at, :updated_at, :milestone, :labels)
  end

  it 'has time estimation attributes' do
    expect(subject).to include(:time_estimate, :total_time_spent, :human_time_estimate, :human_total_time_spent)
  end

  context 'when issue got moved' do
    let(:public_project) { create(:project, :public) }
    let(:member) { create(:user) }
    let(:non_member) { create(:user) }
    let(:issue) { create(:issue, project: public_project) }

    before do
      project.add_developer(member)
      public_project.add_developer(member)
      Issues::MoveService.new(public_project, member).execute(issue, project)
    end

    context 'when user cannot read target project' do
      it 'does not return moved_to_id' do
        request = double('request', current_user: non_member)

        response = described_class.new(issue, request: request).as_json

        expect(response[:moved_to_id]).to be_nil
      end
    end

    context 'when user can read target project' do
      it 'returns moved moved_to_id' do
        request = double('request', current_user: member)

        response = described_class.new(issue, request: request).as_json

        expect(response[:moved_to_id]).to eq(issue.moved_to_id)
      end
    end
  end
end
