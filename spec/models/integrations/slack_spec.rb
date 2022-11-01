# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Slack do
  it_behaves_like Integrations::SlackMattermostNotifier, 'Slack'
  it_behaves_like Integrations::BaseSlackNotification, factory: :integrations_slack
end
