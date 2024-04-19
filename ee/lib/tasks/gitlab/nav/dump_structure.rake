# frozen_string_literal: true

return if Rails.env.production?

namespace :gitlab do
  namespace :nav do
    desc "GitLab | Nav | Dump the complete navigation structure for all navigation contexts"
    task :dump_structure, [] => :gitlab_environment do
      dumper = Tasks::Gitlab::Nav::DumpStructure.new
      puts dumper.dump
    end
  end
end
