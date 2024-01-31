# frozen_string_literal: true

RSpec.shared_examples 'syncs all data from an epic to a work item' do
  it 'sets the same basic epic data to the work item', :aggregate_failures do
    subject

    epic.reload
    work_item = epic.work_item

    expect(epic).to be_persisted
    expect(work_item).to be_valid

    expect(work_item.work_item_type.name).to eq('Epic')
    expect(work_item.namespace).to eq(epic.group)
    expect(work_item.title).to eq epic.title
    expect(work_item.title_html).to eq epic.title_html
    expect(work_item.description).to eq epic.description
    expect(work_item.description_html).to eq epic.description_html
    expect(work_item.updated_by).to eq epic.updated_by
    expect(work_item.last_edited_by).to eq epic.last_edited_by
    expect(work_item.last_edited_at).to eq epic.last_edited_at
    expect(work_item.closed_by).to eq epic.closed_by
    expect(work_item.closed_at).to eq epic.closed_at
    expect(work_item.confidential).to eq epic.confidential
    expect(work_item.iid).to eq(epic.iid)
    expect(work_item.state).to eq(epic.state)
    expect(work_item.author).to eq(epic.author)
    expect(work_item.created_at).to eq(epic.created_at)
    expect(work_item.state).to eq(epic.state)
    expect(work_item.external_key).to eq(epic.external_key)
    expect(work_item.lock_version).to eq(epic.lock_version)

    # Data we do not want to sync yet
    expect(work_item.notes).to be_empty
    expect(work_item.labels).to be_empty
  end
end
