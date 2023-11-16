# frozen_string_literal: true

RSpec.shared_context 'with sample production epics and issues' do
  include DuoChatFixtureHelpers

  let_it_be(:epics) { load_fixture('epics').map(&:deep_symbolize_keys) }
  let_it_be(:issues) { load_fixture('issues').map(&:deep_symbolize_keys) }

  before do
    # Note: In SaaS simulation mode,
    # the url must be `https://gitlab.com` but the routing helper returns `localhost`
    # and breaks GitLab ReferenceExtractor
    stub_default_url_options(host: "gitlab.com", protocol: "https")

    # link_reference_pattern is memoized for Issue
    # and stubbed url (gitlab.com) is not used to derive the link reference pattern.
    Issue.instance_variable_set(:@link_reference_pattern, nil)
  end

  before_all do
    (epics + issues).each { |issuable| create_users(issuable) }
    epics.each { |epic| restore_epic(epic) }
    issues.each { |issue| restore_issue(issue) }
  end
end
