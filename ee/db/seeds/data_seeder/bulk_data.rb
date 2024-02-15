# frozen_string_literal: true

require 'ffaker'

class DataSeeder
  # @example bundle exec rake "ee:gitlab:seed:data_seeder[bulk_data.rb]"
  # @example GITLAB_LOG_LEVEL=debug bundle exec rake "ee:gitlab:seed:data_seeder[bulk_data.rb]"
  def seed
    build_super_group_labels
    build_subgroups
  end

  private

  def uuid
    SecureRandom.uuid
  end

  # Generate a random number
  # @return [Integer] random number
  def random_number
    rand(1..3)
  end

  def random_future_date
    random_number.days.from_now
  end

  def random_past_date
    random_number.days.ago
  end

  def random_text
    FFaker::Lorem.paragraph
  end

  # @return [Array<Symbol>] random traits
  def random_traits_for(factory)
    FactoryBot.factories.find(factory).defined_traits.map(&:name).sample(rand(0..2)).map(&:to_sym)
  end

  # Build Group Labels in the Supergroup
  def build_super_group_labels
    random_number.times do
      build(:group_label, group: @group, title: uuid, &:save)
    end
  end

  # Build subgroups in the Supergroup
  def build_subgroups
    random_number.times do
      build(:group, name: uuid, parent: @group) do |subgroup|
        next unless subgroup.save

        build_group_labels(subgroup)
        build_milestones(subgroup)
        build_epics(subgroup)
        build_projects(subgroup)
      end
    end
  end

  # Build Group Labels for a Group
  # @param [Group] group
  def build_group_labels(group)
    build(:group_label, group: group, title: uuid, &:save)
  end

  # Build Milestones for a Group
  # @param [Group] group
  def build_milestones(group)
    build(:milestone, :on_group, *random_traits_for(:milestone), title: uuid, group: group, &:save)
  end

  # Build Epics for a Group
  # @param [Group] group
  def build_epics(group)
    random_number.times do
      build(:epic, *random_traits_for(:epic), group: group, author: @owner, &:save)
    end
  end

  # Build Projects
  # @param [Group] subgroup
  def build_projects(subgroup)
    random_number.times do
      build(:project, *random_traits_for(:project), path: uuid, group: subgroup) do |project|
        project.description = random_text

        next unless project.save

        build_project_labels(project)
        build_issues(project)
        build_merge_requests(project)
      end
    end
  end

  # Build Project Labels
  # @param [Project] project
  def build_project_labels(project)
    build(:label, project: project, title: uuid) do |label|
      label.description = random_text
      label.save
    end
  end

  # Build Issues for a Project
  # @param [Project] project
  def build_issues(project)
    random_number.times do
      build(:issue, *random_traits_for(:issue), project: project, author: @owner) do |issue|
        issue.description = random_text
        issue.due_date = random_future_date

        next unless issue.save

        # Assign random Super Group Labels to issues
        issue.labels << @group.labels.sample(rand(0..@group.labels.count))
        # Assign random Group Labels to issues
        issue.labels << project.group.labels.sample(rand(0..project.group.labels.count))
        # Assign random Project Labels to issues
        issue.labels << project.labels.sample(rand(0..project.labels.count))

        assign_random_weight(issue)
        assign_random_milestone(issue)

        # Notes
        random_number.times do
          create(:note, noteable: issue, project: project)
        end
      end
    end
  end

  # Build Merge Requests for a Project
  # @param [Project] project
  def build_merge_requests(project)
    random_number.times do
      build(:merge_request, *random_traits_for(:merge_request), source_project: project,
        author: @owner) do |merge_request|
        merge_request.assignee = @owner

        # Assign random Super group labels
        merge_request.labels << @group.labels.sample(rand(0..@group.labels.count))
        # Assign random Group labels
        merge_request.labels << project.group.labels.sample(rand(0..project.group.labels.count))
        # Assign random Project labels
        merge_request.labels << project.labels.sample(rand(0..project.labels.count))
        merge_request.description = random_text

        merge_request.save
      end
    end
  end

  # Assign a random Weight to an Issue
  # @param [Issue] issue
  def assign_random_weight(issue)
    create(
      :resource_weight_event,
      issue: issue,
      user: @owner,
      weight: random_number,
      created_at: random_past_date
    )
  end

  # Assign a random Milestone to an Issue
  # @param [Issue] issue
  def assign_random_milestone(issue)
    create(
      :resource_milestone_event,
      issue: issue,
      milestone: issue.project.group.milestones.sample,
      created_at: random_past_date,
      action: 'add'
    )
  end
end
