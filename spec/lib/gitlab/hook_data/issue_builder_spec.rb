# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HookData::IssueBuilder, feature_category: :webhooks do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:label) { create(:label, project: project) }
  let_it_be(:issue) { create(:labeled_issue, labels: [label], project: project) }
  let_it_be(:contact) { create(:contact, group: project.group) }
  let_it_be(:issue_contact) { create(:issue_customer_relations_contact, issue: issue, contact: contact) }

  let(:builder) { described_class.new(issue) }

  describe '#build' do
    let(:data) { builder.build }

    it 'includes safe attribute' do
      %w[
        assignee_id
        author_id
        closed_at
        confidential
        created_at
        description
        discussion_locked
        due_date
        id
        iid
        last_edited_at
        last_edited_by_id
        milestone_id
        moved_to_id
        duplicated_to_id
        project_id
        relative_position
        state_id
        time_estimate
        title
        updated_at
        updated_by_id
      ].each do |key|
        expect(data).to include(key)
      end
    end

    it 'includes additional attrs' do
      expect(data).to include(:total_time_spent)
      expect(data).to include(:time_change)
      expect(data).to include(:human_time_estimate)
      expect(data).to include(:human_total_time_spent)
      expect(data).to include(:human_time_change)
      expect(data).to include(:assignee_ids)
      expect(data).to include(:state)
      expect(data).to include(:severity)
      expect(data).to include('labels' => [label.hook_attrs])
      expect(data).to include('customer_relations_contacts' => [contact.reload.hook_attrs])
    end

    context 'when the issue has an image in the description' do
      let(:issue_with_description) { create(:issue, description: 'test![Issue_Image](/uploads/abc/Issue_Image.png)') }
      let(:builder) { described_class.new(issue_with_description) }

      it 'sets the image to use an absolute URL' do
        expected_path = "#{issue_with_description.project.path_with_namespace}/uploads/abc/Issue_Image.png"

        expect(data[:description])
          .to eq("test![Issue_Image](#{Settings.gitlab.url}/#{expected_path})")
      end
    end

    context 'for incident' do
      let_it_be(:issue) { create(:incident, :with_escalation_status) }

      it 'includes additional attr' do
        expect(data).to include(:escalation_status)
      end
    end
  end
end
