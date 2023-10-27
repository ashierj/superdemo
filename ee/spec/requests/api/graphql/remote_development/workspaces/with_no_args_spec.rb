# frozen_string_literal: true

require 'spec_helper'
require_relative './shared'

RSpec.describe 'Query.workspaces', feature_category: :remote_development do
  include_context 'with other user'

  let_it_be(:workspace) { create(:workspace) }
  let_it_be(:authorized_user) { workspace.user }

  # create workspace owned by different user, to ensure it is not returned by the query
  let_it_be(:non_matching_workspace) { create(:workspace, user: other_user) }

  let(:args) { {} }

  it_behaves_like 'a fully working Query.workspaces query'
end
