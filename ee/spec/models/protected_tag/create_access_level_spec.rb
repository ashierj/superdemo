# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedTag::CreateAccessLevel, feature_category: :source_code_management do
  include_examples 'protected ref access configured for users', :protected_tag
  include_examples 'protected ref access configured for groups', :protected_tag
end
