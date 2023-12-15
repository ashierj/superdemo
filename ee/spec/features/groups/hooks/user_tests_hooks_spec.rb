# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "User tests hooks", :js, feature_category: :webhooks do
  include StubRequests

  let!(:group) { create(:group) }
  let!(:hook) { create(:group_hook, group: group) }
  let!(:user) { create(:user) }

  before do
    # TODO: Remove the debug_with_puts statements below! Used for debugging purposes.
    # TODO: https://gitlab.com/gitlab-org/quality/engineering-productivity/team/-/issues/323#note_1688925316
    debug_with_puts "Before group.add_owner(user)"
    group.add_owner(user)
    debug_with_puts "After group.add_owner(user)"

    debug_with_puts "Before sign_in(user)"
    sign_in(user)
    debug_with_puts "After sign_in(user)"

    debug_with_puts "Before visit(group_hooks_path(group))"
    visit(group_hooks_path(group))
    debug_with_puts "After visit(group_hooks_path(group))"
    debug_with_puts "Showing hook.url: #{hook.url}"
  end

  context "when project is not empty" do
    let!(:project) do
      debug_with_puts "Before create(:project, :repository, group: group)"
      result = create(:project, :repository, group: group)
      debug_with_puts "After create(:project, :repository, group: group)"

      result
    end

    context "when URL is valid" do
      before do
        debug_with_puts "Before trigger_hook"
        trigger_hook
        debug_with_puts "After trigger_hook"
      end

      it "triggers a hook" do
        debug_with_puts "Before test expectations"
        expect(page).to have_current_path(group_hooks_path(group), ignore_query: true)
        expect(page).to have_selector('[data-testid="alert-info"]', text: "Hook executed successfully: HTTP 200")
        debug_with_puts "After test expectations"
      end
    end

    context "when URL is invalid" do
      before do
        debug_with_puts "Before stub_full_request(hook.url, method: :post)"
        stub_full_request(hook.url, method: :post).to_raise(SocketError.new("Failed to open"))
        debug_with_puts "After stub_full_request(hook.url, method: :post)"

        debug_with_puts "Before click_button_link"
        click_button('Test')
        click_link('Push events')
        debug_with_puts "After click_button_link"
      end

      it do
        debug_with_puts "Before test expectations"
        expect(page).to have_selector('[data-testid="alert-danger"]', text: "Hook execution failed: Failed to open")
        debug_with_puts "After test expectations"
      end
    end
  end

  context "when project is empty" do
    let!(:project) do
      debug_with_puts "Before create(:project, group: group)"
      result = create(:project, group: group)
      debug_with_puts "After create(:project, group: group)"

      result
    end

    before do
      debug_with_puts "Before trigger_hook"
      trigger_hook
      debug_with_puts "Before trigger_hook"
    end

    it do
      debug_with_puts "Before test expectations"
      expect(page).to have_selector('[data-testid="alert-danger"]', text: 'Hook execution failed. Ensure the group has a project with commits.')
      debug_with_puts "After test expectations"
    end
  end

  private

  # TODO: Remove the debug_with_puts statements below! Used for debugging purposes.
  # TODO: https://gitlab.com/gitlab-org/quality/engineering-productivity/team/-/issues/323#note_1688925316
  def trigger_hook
    debug_with_puts "before trigger_hook#stub_full_request"
    stub_full_request(hook.url, method: :post).to_return(status: 200)
    debug_with_puts "after trigger_hook#stub_full_request"

    debug_with_puts "before click_button_Test"
    click_button('Test')
    debug_with_puts "after click_button_Test"

    debug_with_puts "before click_link_Push events"
    click_link('Push events')
    debug_with_puts "after click_link_Push events"
  end

  # TODO: Remove the debug_with_puts statements below! Used for debugging purposes.
  # TODO: https://gitlab.com/gitlab-org/quality/engineering-productivity/team/-/issues/323#note_1688925316
  def debug_with_puts(message)
    return unless ENV['CI'] # rubocop:disable RSpec/AvoidConditionalStatements -- Debug information only in the CI

    puts "[#{Time.current}] #{message}"
  end
end
