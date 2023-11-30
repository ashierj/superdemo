# frozen_string_literal: true

namespace :gitlab do
  namespace :duo do
    desc 'GitLab | Duo | Enable GitLab Duo features on the specified group'
    task :setup, [:root_group_path] => :environment do |_, args|
      Gitlab::Duo::Developments::Setup.new(args).execute
    end
  end
end
