# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranch::MergeAccessLevel, feature_category: :source_code_management do
  include_examples 'protected ref access configured for users', :protected_branch
  include_examples 'ee protected branch access'
end
