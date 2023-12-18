# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::CiRunnerUsageByProject, feature_category: :fleet_visibility do
  include EmailSpec::Matchers

  include_context 'gitlab email notification'

  describe '#runner_usage_by_project_csv_email', travel_to: '2023-12-24' do
    let_it_be(:user_email) { 'sam@email.com' }
    let_it_be(:current_user) { build_stubbed :user, email: user_email, name: 'UserName' }

    let(:from_time) { DateTime.new(2023, 11, 1) }
    let(:to_time) { DateTime.new(2023, 11, 30, 23, 59, 59) }
    let(:content_type) { 'text/csv' }
    let(:csv_data) { 'csv,separated,things' }
    let(:export_status) { { rows_expected: 3, rows_written: 2, truncated: false } }

    let(:expected_filename) { "ci_runner_usage_report_#{from_time.iso8601}_#{to_time.iso8601}.csv" }
    let(:expected_plain_text) { 'Your CSV export of the top 2 projects has been added to this email as an attachment.' }
    let(:expected_html_text) do
      'Your CI runner usage CSV export containing the top 2 projects has been added to this email as an attachment.'
    end

    subject(:mail) do
      Notify.runner_usage_by_project_csv_email(
        user: current_user,
        from_time: from_time,
        to_time: to_time,
        csv_data: csv_data,
        export_status: export_status
      )
    end

    it 'renders an email with attachment' do
      expect(mail.subject).to eq('Exported CI Runner usage (2023-11-01 - 2023-11-30)')
      expect(mail.to).to contain_exactly(user_email)
      expect(mail.text_part.to_s).to include(expected_plain_text)
      expect(mail.html_part.to_s).to include(expected_html_text)
      expect(mail.attachments.size).to eq(1)

      attachment = mail.attachments.first

      expect(attachment.content_type).to eq(content_type)
      expect(attachment.filename).to eq(expected_filename)
    end
  end
end
