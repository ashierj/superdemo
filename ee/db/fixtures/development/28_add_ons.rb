# frozen_string_literal: true

Gitlab::Seeder.quiet do
  GitlabSubscriptions::AddOn.names.each_key do |name|
    GitlabSubscriptions::AddOn.create!(name: name, description: GitlabSubscriptions::AddOn.descriptions[name.to_sym])

    print '.'
  end
end
