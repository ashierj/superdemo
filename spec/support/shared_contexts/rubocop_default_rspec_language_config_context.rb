# frozen_string_literal: true

# From https://github.com/rubocop/rubocop-rspec/blob/master/spec/shared/default_rspec_language_config_context.rb
# This can be removed once we have https://github.com/rubocop/rubocop-rspec/pull/1377

RSpec.shared_context 'with default RSpec/Language config' do
  include_context 'config'

  # Deep duplication is needed to prevent config leakage between examples
  let(:other_cops) do
    default_language = RuboCop::ConfigLoader
      .default_configuration['RSpec']['Language']
    default_include = RuboCop::ConfigLoader
      .default_configuration['RSpec']['Include']
    { 'RSpec' =>
      {
        'Include' => default_include,
        'Language' => deep_dup(default_language)
      } }
  end

  def deep_dup(object)
    case object
    when Array
      object.map { |item| deep_dup(item) }
    when Hash
      object.transform_values { |value| deep_dup(value) }
    else
      object # only collections undergo modifications and need duping
    end
  end
end
