# frozen_string_literal: true

RSpec.shared_context 'with sample production epics and issues' do
  include DuoChatFixtureHelpers

  let_it_be(:epics) { load_fixture('epics').map(&:deep_symbolize_keys) }
  let_it_be(:issues) { load_fixture('issues').map(&:deep_symbolize_keys) }

  before_all do
    (epics + issues).each { |issuable| create_users(issuable) }
    epics.each { |epic| restore_epic(epic) }
    issues.each { |issue| restore_issue(issue) }
  end
end
