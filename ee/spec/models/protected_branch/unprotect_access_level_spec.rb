# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranch::UnprotectAccessLevel, feature_category: :source_code_management do
  include_examples 'protected branch access'
  include_examples 'protected ref access allowed_access_levels', excludes: [Gitlab::Access::NO_ACCESS]
  include_examples 'protected ref access configured for users', :protected_branch
  include_examples 'protected ref access configured for groups', :protected_branch
end
