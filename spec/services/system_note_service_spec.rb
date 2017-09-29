require 'spec_helper'

describe SystemNoteService, services: true do
  include Gitlab::Routing

  let(:project)  { create(:empty_project) }
  let(:author)   { create(:user) }
  let(:noteable) { create(:issue, project: project) }
  let(:issue)    { noteable }

  shared_examples_for 'a system note' do
    let(:expected_noteable) { noteable }
    let(:commit_count)      { nil }

    it 'is valid' do
      expect(subject).to be_valid
    end

    it 'sets the noteable model' do
      expect(subject.noteable).to eq expected_noteable
    end

    it 'sets the project' do
      expect(subject.project).to eq project
    end

    it 'sets the author' do
      expect(subject.author).to eq author
    end

    it 'is a system note' do
      expect(subject).to be_system
    end

    context 'metadata' do
      it 'creates a new system note metadata record' do
        expect { subject }.to change{ SystemNoteMetadata.count }.from(0).to(1)
      end

      it 'creates a record correctly' do
        metadata = subject.system_note_metadata

        expect(metadata.commit_count).to eq(commit_count)
        expect(metadata.action).to eq(action)
      end
    end
  end

  describe '.add_commits' do
    subject { described_class.add_commits(noteable, project, author, new_commits, old_commits, oldrev) }

    let(:project)     { create(:project, :repository) }
    let(:noteable)    { create(:merge_request, source_project: project) }
    let(:new_commits) { noteable.commits }
    let(:old_commits) { [] }
    let(:oldrev)      { nil }

    it_behaves_like 'a system note' do
      let(:commit_count) { new_commits.size }
      let(:action)       { 'commit' }
    end

    describe 'note body' do
      let(:note_lines) { subject.note.split("\n").reject(&:blank?) }

      describe 'comparison diff link line' do
        it 'adds the comparison text' do
          expect(note_lines[2]).to match "[Compare with previous version]"
        end
      end

      context 'without existing commits' do
        it 'adds a message header' do
          expect(note_lines[0]).to eq "added #{new_commits.size} commits"
        end

        it 'adds a message line for each commit' do
          new_commits.each_with_index do |commit, i|
            # Skip the header
            expect(HTMLEntities.new.decode(note_lines[i + 1])).to eq "* #{commit.short_id} - #{commit.title}"
          end
        end
      end

      describe 'summary line for existing commits' do
        let(:summary_line) { note_lines[1] }

        context 'with one existing commit' do
          let(:old_commits) { [noteable.commits.last] }

          it 'includes the existing commit' do
            expect(summary_line).to eq "* #{old_commits.first.short_id} - 1 commit from branch `feature`"
          end
        end

        context 'with multiple existing commits' do
          let(:old_commits) { noteable.commits[3..-1] }

          context 'with oldrev' do
            let(:oldrev) { noteable.commits[2].id }

            it 'includes a commit range' do
              expect(summary_line).to start_with "* #{Commit.truncate_sha(oldrev)}...#{old_commits.last.short_id}"
            end

            it 'includes a commit count' do
              expect(summary_line).to end_with " - 26 commits from branch `feature`"
            end
          end

          context 'without oldrev' do
            it 'includes a commit range' do
              expect(summary_line).to start_with "* #{old_commits[0].short_id}..#{old_commits[-1].short_id}"
            end

            it 'includes a commit count' do
              expect(summary_line).to end_with " - 26 commits from branch `feature`"
            end
          end

          context 'on a fork' do
            before do
              expect(noteable).to receive(:for_fork?).and_return(true)
            end

            it 'includes the project namespace' do
              expect(summary_line).to end_with "`#{noteable.target_project_namespace}:feature`"
            end
          end
        end
      end
    end
  end

  describe '.change_assignee' do
    subject { described_class.change_assignee(noteable, project, author, assignee) }

    let(:assignee) { create(:user) }

    it_behaves_like 'a system note' do
      let(:action) { 'assignee' }
    end

    context 'when assignee added' do
      it 'sets the note text' do
        expect(subject.note).to eq "assigned to @#{assignee.username}"
      end
    end

    context 'when assignee removed' do
      let(:assignee) { nil }

      it 'sets the note text' do
        expect(subject.note).to eq 'removed assignee'
      end
    end
  end

  describe '.change_issue_assignees' do
    subject { described_class.change_issue_assignees(noteable, project, author, [assignee]) }

    let(:assignee) { create(:user) }
    let(:assignee1) { create(:user) }
    let(:assignee2) { create(:user) }
    let(:assignee3) { create(:user) }

    it_behaves_like 'a system note' do
      let(:action) { 'assignee' }
    end

    def build_note(old_assignees, new_assignees)
      issue.assignees = new_assignees
      described_class.change_issue_assignees(issue, project, author, old_assignees).note
    end

    it 'builds a correct phrase when an assignee is added to a non-assigned issue' do
      expect(build_note([], [assignee1])).to eq "assigned to @#{assignee1.username}"
    end

    it 'builds a correct phrase when assignee removed' do
      expect(build_note([assignee1], [])).to eq 'removed assignee'
    end

    it 'builds a correct phrase when assignees changed' do
      expect(build_note([assignee1], [assignee2])).to eq \
        "assigned to @#{assignee2.username} and unassigned @#{assignee1.username}"
    end

    it 'builds a correct phrase when three assignees removed and one added' do
      expect(build_note([assignee, assignee1, assignee2], [assignee3])).to eq \
        "assigned to @#{assignee3.username} and unassigned @#{assignee.username}, @#{assignee1.username}, and @#{assignee2.username}"
    end

    it 'builds a correct phrase when one assignee changed from a set' do
      expect(build_note([assignee, assignee1], [assignee, assignee2])).to eq \
        "assigned to @#{assignee2.username} and unassigned @#{assignee1.username}"
    end

    it 'builds a correct phrase when one assignee removed from a set' do
      expect(build_note([assignee, assignee1, assignee2], [assignee, assignee1])).to eq \
        "unassigned @#{assignee2.username}"
    end
  end

  describe '.change_label' do
    subject { described_class.change_label(noteable, project, author, added, removed) }

    let(:labels)  { create_list(:label, 2) }
    let(:added)   { [] }
    let(:removed) { [] }

    it_behaves_like 'a system note' do
      let(:action) { 'label' }
    end

    context 'with added labels' do
      let(:added)   { labels }
      let(:removed) { [] }

      it 'sets the note text' do
        expect(subject.note).to eq "added ~#{labels[0].id} ~#{labels[1].id} labels"
      end
    end

    context 'with removed labels' do
      let(:added)   { [] }
      let(:removed) { labels }

      it 'sets the note text' do
        expect(subject.note).to eq "removed ~#{labels[0].id} ~#{labels[1].id} labels"
      end
    end

    context 'with added and removed labels' do
      let(:added)   { [labels[0]] }
      let(:removed) { [labels[1]] }

      it 'sets the note text' do
        expect(subject.note).to eq "added ~#{labels[0].id} and removed ~#{labels[1].id} labels"
      end
    end
  end

  describe '.change_milestone' do
    subject { described_class.change_milestone(noteable, project, author, milestone) }

    let(:milestone) { create(:milestone, project: project) }

    it_behaves_like 'a system note' do
      let(:action) { 'milestone' }
    end

    context 'when milestone added' do
      it 'sets the note text' do
        expect(subject.note).to eq "changed milestone to #{milestone.to_reference}"
      end
    end

    context 'when milestone removed' do
      let(:milestone) { nil }

      it 'sets the note text' do
        expect(subject.note).to eq 'removed milestone'
      end
    end
  end

  describe '.change_status' do
    subject { described_class.change_status(noteable, project, author, status, source) }

    context 'with status reopened' do
      let(:status) { 'reopened' }
      let(:source) { nil }

      it_behaves_like 'a system note' do
        let(:action) { 'opened' }
      end
    end

    context 'with a source' do
      let(:status) { 'opened' }
      let(:source) { double('commit', gfm_reference: 'commit 123456') }

      it 'sets the note text' do
        expect(subject.note).to eq "#{status} via commit 123456"
      end
    end
  end

  describe '.merge_when_pipeline_succeeds' do
    let(:project)  { create(:project, :repository) }
    let(:pipeline) { build(:ci_pipeline_without_jobs )}
    let(:noteable) do
      create(:merge_request, source_project: project, target_project: project)
    end

    subject { described_class.merge_when_pipeline_succeeds(noteable, project, author, noteable.diff_head_commit) }

    it_behaves_like 'a system note' do
      let(:action) { 'merge' }
    end

    it "posts the 'merge when pipeline succeeds' system note" do
      expect(subject.note).to match(/enabled an automatic merge when the pipeline for (\w+\/\w+@)?\h{40} succeeds/)
    end
  end

  describe '.cancel_merge_when_pipeline_succeeds' do
    let(:project) { create(:project, :repository) }
    let(:noteable) do
      create(:merge_request, source_project: project, target_project: project)
    end

    subject { described_class.cancel_merge_when_pipeline_succeeds(noteable, project, author) }

    it_behaves_like 'a system note' do
      let(:action) { 'merge' }
    end

    it "posts the 'merge when pipeline succeeds' system note" do
      expect(subject.note).to eq  "canceled the automatic merge"
    end
  end

  describe '.change_title' do
    let(:noteable) { create(:issue, project: project, title: 'Lorem ipsum') }

    subject { described_class.change_title(noteable, project, author, 'Old title') }

    context 'when noteable responds to `title`' do
      it_behaves_like 'a system note' do
        let(:action) { 'title' }
      end

      it 'sets the note text' do
        expect(subject.note)
          .to eq "changed title from **{-Old title-}** to **{+Lorem ipsum+}**"
      end
    end
  end

  describe '.change_description' do
    subject { described_class.change_description(noteable, project, author) }

    context 'when noteable responds to `description`' do
      it_behaves_like 'a system note' do
        let(:action) { 'description' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq('changed the description')
      end
    end
  end

  describe '.change_issue_confidentiality' do
    subject { described_class.change_issue_confidentiality(noteable, project, author) }

    context 'issue has been made confidential' do
      before do
        noteable.update_attribute(:confidential, true)
      end

      it_behaves_like 'a system note' do
        let(:action) { 'confidential' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq 'made the issue confidential'
      end
    end

    context 'issue has been made visible' do
      it_behaves_like 'a system note' do
        let(:action) { 'visible' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq 'made the issue visible to everyone'
      end
    end
  end

  describe '.change_branch' do
    subject { described_class.change_branch(noteable, project, author, 'target', old_branch, new_branch) }

    let(:project)    { create(:project, :repository) }
    let(:old_branch) { 'old_branch'}
    let(:new_branch) { 'new_branch'}

    it_behaves_like 'a system note' do
      let(:action) { 'branch' }
    end

    context 'when target branch name changed' do
      it 'sets the note text' do
        expect(subject.note).to eq "changed target branch from `#{old_branch}` to `#{new_branch}`"
      end
    end
  end

  describe '.change_branch_presence' do
    subject { described_class.change_branch_presence(noteable, project, author, :source, 'feature', :delete) }

    let(:project) { create(:project, :repository) }

    it_behaves_like 'a system note' do
      let(:action) { 'branch' }
    end

    context 'when source branch deleted' do
      it 'sets the note text' do
        expect(subject.note).to eq "deleted source branch `feature`"
      end
    end
  end

  describe '.new_issue_branch' do
    subject { described_class.new_issue_branch(noteable, project, author, "1-mepmep") }

    let(:project) { create(:project, :repository) }

    it_behaves_like 'a system note' do
      let(:action) { 'branch' }
    end

    context 'when a branch is created from the new branch button' do
      it 'sets the note text' do
        expect(subject.note).to start_with("created branch [`1-mepmep`]")
      end
    end
  end

  describe '.cross_reference' do
    subject { described_class.cross_reference(noteable, mentioner, author) }

    let(:mentioner) { create(:issue, project: project) }

    it_behaves_like 'a system note' do
      let(:action) { 'cross_reference' }
    end

    context 'when cross-reference disallowed' do
      before do
        expect(described_class).to receive(:cross_reference_disallowed?).and_return(true)
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end

      it 'does not create a system note metadata record' do
        expect { subject }.not_to change{ SystemNoteMetadata.count }
      end
    end

    context 'when cross-reference allowed' do
      before do
        expect(described_class).to receive(:cross_reference_disallowed?).and_return(false)
      end

      it_behaves_like 'a system note' do
        let(:action) { 'cross_reference' }
      end

      describe 'note_body' do
        context 'cross-project' do
          let(:project2)  { create(:project, :repository) }
          let(:mentioner) { create(:issue, project: project2) }

          context 'from Commit' do
            let(:mentioner) { project2.repository.commit }

            it 'references the mentioning commit' do
              expect(subject.note).to eq "mentioned in commit #{mentioner.to_reference(project)}"
            end
          end

          context 'from non-Commit' do
            it 'references the mentioning object' do
              expect(subject.note).to eq "mentioned in issue #{mentioner.to_reference(project)}"
            end
          end
        end

        context 'within the same project' do
          context 'from Commit' do
            let(:project) { create(:project, :repository) }
            let(:mentioner) { project.repository.commit }

            it 'references the mentioning commit' do
              expect(subject.note).to eq "mentioned in commit #{mentioner.to_reference}"
            end
          end

          context 'from non-Commit' do
            it 'references the mentioning object' do
              expect(subject.note).to eq "mentioned in issue #{mentioner.to_reference}"
            end
          end
        end
      end
    end
  end

  describe '.cross_reference_disallowed?' do
    context 'when mentioner is not a MergeRequest' do
      it 'is falsey' do
        mentioner = noteable.dup
        expect(described_class.cross_reference_disallowed?(noteable, mentioner))
          .to be_falsey
      end
    end

    context 'when mentioner is a MergeRequest' do
      let(:project)   { create(:project, :repository) }
      let(:mentioner) { create(:merge_request, :simple, source_project: project) }
      let(:noteable)  { project.commit }

      it 'is truthy when noteable is in commits' do
        expect(mentioner).to receive(:commits).and_return([noteable])
        expect(described_class.cross_reference_disallowed?(noteable, mentioner))
          .to be_truthy
      end

      it 'is falsey when noteable is not in commits' do
        expect(mentioner).to receive(:commits).and_return([])
        expect(described_class.cross_reference_disallowed?(noteable, mentioner))
          .to be_falsey
      end
    end

    context 'when notable is an ExternalIssue' do
      let(:noteable) { ExternalIssue.new('EXT-1234', project) }
      it 'is truthy' do
        mentioner = noteable.dup
        expect(described_class.cross_reference_disallowed?(noteable, mentioner))
          .to be_truthy
      end
    end
  end

  describe '.cross_reference_exists?' do
    let(:project) { create(:project, :repository) }
    let(:commit0) { project.commit }
    let(:commit1) { project.commit('HEAD~2') }

    context 'issue from commit' do
      before do
        # Mention issue (noteable) from commit0
        described_class.cross_reference(noteable, commit0, author)
      end

      it 'is truthy when already mentioned' do
        expect(described_class.cross_reference_exists?(noteable, commit0))
          .to be_truthy
      end

      it 'is falsey when not already mentioned' do
        expect(described_class.cross_reference_exists?(noteable, commit1))
          .to be_falsey
      end

      context 'legacy capitalized cross reference' do
        before do
          # Mention issue (noteable) from commit0
          system_note = described_class.cross_reference(noteable, commit0, author)
          system_note.update(note: system_note.note.capitalize)
        end

        it 'is truthy when already mentioned' do
          expect(described_class.cross_reference_exists?(noteable, commit0))
            .to be_truthy
        end
      end
    end

    context 'commit from commit' do
      before do
        # Mention commit1 from commit0
        described_class.cross_reference(commit0, commit1, author)
      end

      it 'is truthy when already mentioned' do
        expect(described_class.cross_reference_exists?(commit0, commit1))
          .to be_truthy
      end

      it 'is falsey when not already mentioned' do
        expect(described_class.cross_reference_exists?(commit1, commit0))
          .to be_falsey
      end

      context 'legacy capitalized cross reference' do
        before do
          # Mention commit1 from commit0
          system_note = described_class.cross_reference(commit0, commit1, author)
          system_note.update(note: system_note.note.capitalize)
        end

        it 'is truthy when already mentioned' do
          expect(described_class.cross_reference_exists?(commit0, commit1))
            .to be_truthy
        end
      end
    end

    context 'commit with cross-reference from fork' do
      let(:author2) { create(:project_member, :reporter, user: create(:user), project: project).user }
      let(:forked_project) do
        fp = Projects::ForkService.new(project, author2).execute
        # The call to project.repository.after_import in RepositoryForkWorker does
        # not reset the @exists variable of @fork_project.repository so we have to
        # explicitely call this method to clear the @exists variable.
        fp.repository.after_import
        fp
      end
      let(:commit2) { forked_project.commit }

      before do
        described_class.cross_reference(noteable, commit0, author2)
      end

      it 'is true when a fork mentions an external issue' do
        expect(described_class.cross_reference_exists?(noteable, commit2))
            .to be true
      end

      context 'legacy capitalized cross reference' do
        before do
          system_note = described_class.cross_reference(noteable, commit0, author2)
          system_note.update(note: system_note.note.capitalize)
        end

        it 'is true when a fork mentions an external issue' do
          expect(described_class.cross_reference_exists?(noteable, commit2))
              .to be true
        end
      end
    end
  end

  describe '.noteable_moved' do
    let(:new_project) { create(:empty_project) }
    let(:new_noteable) { create(:issue, project: new_project) }

    subject do
      described_class.noteable_moved(noteable, project, new_noteable, author, direction: direction)
    end

    shared_examples 'cross project mentionable' do
      include MarkupHelper

      it 'contains cross reference to new noteable' do
        expect(subject.note).to include cross_project_reference(new_project, new_noteable)
      end

      it 'mentions referenced noteable' do
        expect(subject.note).to include new_noteable.to_reference
      end

      it 'mentions referenced project' do
        expect(subject.note).to include new_project.path_with_namespace
      end
    end

    context 'moved to' do
      let(:direction) { :to }

      it_behaves_like 'cross project mentionable'
      it_behaves_like 'a system note' do
        let(:action) { 'moved' }
      end

      it 'notifies about noteable being moved to' do
        expect(subject.note).to match('moved to')
      end
    end

    context 'moved from' do
      let(:direction) { :from }

      it_behaves_like 'cross project mentionable'
      it_behaves_like 'a system note' do
        let(:action) { 'moved' }
      end

      it 'notifies about noteable being moved from' do
        expect(subject.note).to match('moved from')
      end
    end

    context 'invalid direction' do
      let(:direction) { :invalid }

      it 'raises error' do
        expect { subject }.to raise_error StandardError, /Invalid direction/
      end
    end
  end

  describe '.new_commit_summary' do
    it 'escapes HTML titles' do
      commit = double(title: '<pre>This is a test</pre>', short_id: '12345678')
      escaped = '* 12345678 - &lt;pre&gt;This is a test&lt;&#x2F;pre&gt;'

      expect(described_class.new_commit_summary([commit])).to eq([escaped])
    end
  end

  describe 'JIRA integration' do
    include JiraServiceHelper

    let(:project)         { create(:jira_project) }
    let(:author)          { create(:user) }
    let(:issue)           { create(:issue, project: project) }
    let(:merge_request)   { create(:merge_request, :simple, target_project: project, source_project: project) }
    let(:jira_issue)      { ExternalIssue.new("JIRA-1", project)}
    let(:jira_tracker)    { project.jira_service }
    let(:commit)          { project.commit }
    let(:comment_url)     { jira_api_comment_url(jira_issue.id) }
    let(:success_message) { "JiraService SUCCESS: Successfully posted to http://jira.example.net." }

    before do
      stub_jira_urls(jira_issue.id)
      jira_service_settings
    end

    def cross_reference(type, link_exists = false)
      noteable = type == 'commit' ? commit : merge_request

      links = []
      if link_exists
        url = if type == 'commit'
                "#{Settings.gitlab.base_url}/#{project.namespace.path}/#{project.path}/commit/#{commit.id}"
              else
                "#{Settings.gitlab.base_url}/#{project.namespace.path}/#{project.path}/merge_requests/#{merge_request.iid}"
              end
        link = double(object: { 'url' => url })
        links << link
        expect(link).to receive(:save!)
      end

      allow(JIRA::Resource::Remotelink).to receive(:all).and_return(links)

      described_class.cross_reference(jira_issue, noteable, author)
    end

    noteable_types = %w(merge_requests commit)

    noteable_types.each do |type|
      context "when noteable is a #{type}" do
        it "blocks cross reference when #{type.underscore}_events is false" do
          jira_tracker.update("#{type}_events" => false)

          expect(cross_reference(type)).to eq("Events for #{type.pluralize.humanize.downcase} are disabled.")
        end

        it "blocks cross reference when #{type.underscore}_events is true" do
          jira_tracker.update("#{type}_events" => true)

          expect(cross_reference(type)).to eq(success_message)
        end
      end

      context 'when a new cross reference is created' do
        it 'creates a new comment and remote link' do
          cross_reference(type)

          expect(WebMock).to have_requested(:post, jira_api_comment_url(jira_issue))
          expect(WebMock).to have_requested(:post, jira_api_remote_link_url(jira_issue))
        end
      end

      context 'when a link exists' do
        it 'updates a link but does not create a new comment' do
          expect(WebMock).not_to have_requested(:post, jira_api_comment_url(jira_issue))

          cross_reference(type, true)
        end
      end
    end

    describe "new reference" do
      before do
        allow(JIRA::Resource::Remotelink).to receive(:all).and_return([])
      end

      context 'for commits' do
        it "creates comment" do
          result = described_class.cross_reference(jira_issue, commit, author)

          expect(result).to eq(success_message)
        end

        it "creates remote link" do
          described_class.cross_reference(jira_issue, commit, author)

          expect(WebMock).to have_requested(:post, jira_api_remote_link_url(jira_issue)).with(
            body: hash_including(
              GlobalID: "GitLab",
              object: {
                url: project_commit_url(project, commit),
                title: "GitLab: Mentioned on commit - #{commit.title}",
                icon: { title: "GitLab", url16x16: "https://gitlab.com/favicon.ico" },
                status: { resolved: false }
              }
            )
          ).once
        end
      end

      context 'for issues' do
        let(:issue)           { create(:issue, project: project) }

        it "creates comment" do
          result = described_class.cross_reference(jira_issue, issue, author)

          expect(result).to eq(success_message)
        end

        it "creates remote link" do
          described_class.cross_reference(jira_issue, issue, author)

          expect(WebMock).to have_requested(:post, jira_api_remote_link_url(jira_issue)).with(
            body: hash_including(
              GlobalID: "GitLab",
              object: {
                url: project_issue_url(project, issue),
                title: "GitLab: Mentioned on issue - #{issue.title}",
                icon: { title: "GitLab", url16x16: "https://gitlab.com/favicon.ico" },
                status: { resolved: false }
              }
            )
          ).once
        end
      end

      context 'for snippets' do
        let(:snippet) { create(:snippet, project: project) }

        it "creates comment" do
          result = described_class.cross_reference(jira_issue, snippet, author)

          expect(result).to eq(success_message)
        end

        it "creates remote link" do
          described_class.cross_reference(jira_issue, snippet, author)

          expect(WebMock).to have_requested(:post, jira_api_remote_link_url(jira_issue)).with(
            body: hash_including(
              GlobalID: "GitLab",
              object: {
                url: project_snippet_url(project, snippet),
                title: "GitLab: Mentioned on snippet - #{snippet.title}",
                icon: { title: "GitLab", url16x16: "https://gitlab.com/favicon.ico" },
                status: { resolved: false }
              }
            )
          ).once
        end
      end
    end

    describe "existing reference" do
      before do
        allow(JIRA::Resource::Remotelink).to receive(:all).and_return([])
        message = "[#{author.name}|http://localhost/#{author.username}] mentioned this issue in [a commit of #{project.path_with_namespace}|http://localhost/#{project.path_with_namespace}/commit/#{commit.id}]:\n'#{commit.title.chomp}'"
        allow_any_instance_of(JIRA::Resource::Issue).to receive(:comments).and_return([OpenStruct.new(body: message)])
      end

      it "does not return success message" do
        result = described_class.cross_reference(jira_issue, commit, author)

        expect(result).not_to eq(success_message)
      end

      it 'does not try to create comment and remote link' do
        subject

        expect(WebMock).not_to have_requested(:post, jira_api_comment_url(jira_issue))
        expect(WebMock).not_to have_requested(:post, jira_api_remote_link_url(jira_issue))
      end
    end
  end

  describe '.relate_issue' do
    let(:noteable_ref) { create(:issue) }

    subject { described_class.relate_issue(noteable, noteable_ref, author) }

    it_behaves_like 'a system note' do
      let(:action) { 'relate' }
    end

    context 'when issue marks another as related' do
      it 'sets the note text' do
        expect(subject.note).to eq "marked this issue as related to #{noteable_ref.to_reference(project)}"
      end
    end
  end

  describe '.unrelate_issue' do
    let(:noteable_ref) { create(:issue) }

    subject { described_class.unrelate_issue(noteable, noteable_ref, author) }

    it_behaves_like 'a system note' do
      let(:action) { 'unrelate' }
    end

    context 'when issue relation is removed' do
      it 'sets the note text' do
        expect(subject.note).to eq "removed the relation with #{noteable_ref.to_reference(project)}"
      end
    end
  end

  describe '.approve_mr' do
    let(:noteable)    { create(:merge_request, source_project: project) }
    subject { described_class.approve_mr(noteable, author) }

    it_behaves_like 'a system note' do
      let(:action) { 'approved' }
    end

    context 'when merge request approved' do
      it 'sets the note text' do
        expect(subject.note).to eq "approved this merge request"
      end
    end
  end

  describe '.unapprove_mr' do
    let(:noteable)    { create(:merge_request, source_project: project) }
    subject { described_class.unapprove_mr(noteable, author) }

    it_behaves_like 'a system note' do
      let(:action) { 'unapproved' }
    end

    context 'when merge request approved' do
      it 'sets the note text' do
        expect(subject.note).to eq "unapproved this merge request"
      end
    end
  end

  describe '.change_time_estimate' do
    subject { described_class.change_time_estimate(noteable, project, author) }

    it_behaves_like 'a system note' do
      let(:action) { 'time_tracking' }
    end

    context 'with a time estimate' do
      it 'sets the note text' do
        noteable.update_attribute(:time_estimate, 277200)

        expect(subject.note).to eq "changed time estimate to 1w 4d 5h"
      end
    end

    context 'without a time estimate' do
      it 'sets the note text' do
        expect(subject.note).to eq "removed time estimate"
      end
    end
  end

  describe '.change_time_spent' do
    # We need a custom noteable in order to the shared examples to be green.
    let(:noteable) do
      mr = create(:merge_request, source_project: project)
      mr.spend_time(duration: 360000, user: author)
      mr.save!
      mr
    end

    subject do
      described_class.change_time_spent(noteable, project, author)
    end

    it_behaves_like 'a system note' do
      let(:action) { 'time_tracking' }
    end

    context 'when time was added' do
      it 'sets the note text' do
        spend_time!(277200)

        expect(subject.note).to eq "added 1w 4d 5h of time spent"
      end
    end

    context 'when time was subtracted' do
      it 'sets the note text' do
        spend_time!(-277200)

        expect(subject.note).to eq "subtracted 1w 4d 5h of time spent"
      end
    end

    context 'when time was removed' do
      it 'sets the note text' do
        spend_time!(:reset)

        expect(subject.note).to eq "removed time spent"
      end
    end

    def spend_time!(seconds)
      noteable.spend_time(duration: seconds, user: author)
      noteable.save!
    end
  end

  describe '.discussion_continued_in_issue' do
    let(:discussion) { create(:diff_note_on_merge_request).to_discussion }
    let(:merge_request) { discussion.noteable }
    let(:project) { merge_request.source_project }
    let(:issue) { create(:issue, project: project) }

    def reloaded_merge_request
      MergeRequest.find(merge_request.id)
    end

    subject { described_class.discussion_continued_in_issue(discussion, project, author, issue) }

    it_behaves_like 'a system note' do
      let(:expected_noteable) { discussion.first_note.noteable }
      let(:action)              { 'discussion' }
    end

    it 'creates a new note in the discussion' do
      # we need to completely rebuild the merge request object, or the `@discussions` on the merge request are not reloaded.
      expect { subject }.to change { reloaded_merge_request.discussions.first.notes.size }.by(1)
    end

    it 'mentions the created issue in the system note' do
      expect(subject.note).to include(issue.to_reference)
    end
  end

  describe '.change_time_estimate' do
    subject { described_class.change_time_estimate(noteable, project, author) }

    it_behaves_like 'a system note' do
      let(:action) { 'time_tracking' }
    end

    context 'with a time estimate' do
      it 'sets the note text' do
        noteable.update_attribute(:time_estimate, 277200)

        expect(subject.note).to eq "changed time estimate to 1w 4d 5h"
      end
    end

    context 'without a time estimate' do
      it 'sets the note text' do
        expect(subject.note).to eq "removed time estimate"
      end
    end
  end

  describe '.change_time_spent' do
    # We need a custom noteable in order to the shared examples to be green.
    let(:noteable) do
      mr = create(:merge_request, source_project: project)
      mr.spend_time(duration: 360000, user: author)
      mr.save!
      mr
    end

    subject do
      described_class.change_time_spent(noteable, project, author)
    end

    it_behaves_like 'a system note' do
      let(:action) { 'time_tracking' }
    end

    context 'when time was added' do
      it 'sets the note text' do
        spend_time!(277200)

        expect(subject.note).to eq "added 1w 4d 5h of time spent"
      end
    end

    context 'when time was subtracted' do
      it 'sets the note text' do
        spend_time!(-277200)

        expect(subject.note).to eq "subtracted 1w 4d 5h of time spent"
      end
    end

    context 'when time was removed' do
      it 'sets the note text' do
        spend_time!(:reset)

        expect(subject.note).to eq "removed time spent"
      end
    end

    def spend_time!(seconds)
      noteable.spend_time(duration: seconds, user: author)
      noteable.save!
    end
  end

  describe '.remove_merge_request_wip' do
    let(:noteable) { create(:issue, project: project, title: 'WIP: Lorem ipsum') }

    subject { described_class.remove_merge_request_wip(noteable, project, author) }

    it_behaves_like 'a system note' do
      let(:action) { 'title' }
    end

    it 'sets the note text' do
      expect(subject.note).to eq 'unmarked as a **Work In Progress**'
    end
  end

  describe '.add_merge_request_wip' do
    let(:noteable) { create(:issue, project: project, title: 'Lorem ipsum') }

    subject { described_class.add_merge_request_wip(noteable, project, author) }

    it_behaves_like 'a system note' do
      let(:action) { 'title' }
    end

    it 'sets the note text' do
      expect(subject.note).to eq 'marked as a **Work In Progress**'
    end
  end

  describe '.add_merge_request_wip_from_commit' do
    let(:project) { create(:project, :repository) }
    let(:noteable) do
      create(:merge_request, source_project: project, target_project: project)
    end

    subject do
      described_class.add_merge_request_wip_from_commit(
        noteable,
        project,
        author,
        noteable.diff_head_commit
      )
    end

    it_behaves_like 'a system note' do
      let(:action) { 'title' }
    end

    it "posts the 'marked as a Work In Progress from commit' system note" do
      expect(subject.note).to match(
        /marked as a \*\*Work In Progress\*\* from #{Commit.reference_pattern}/
      )
    end
  end

  describe '.change_task_status' do
    let(:noteable) { create(:issue, project: project) }
    let(:task)     { double(:task, complete?: true, source: 'task') }

    subject { described_class.change_task_status(noteable, project, author, task) }

    it_behaves_like 'a system note' do
      let(:action) { 'task' }
    end

    it "posts the 'marked the task as complete' system note" do
      expect(subject.note).to eq("marked the task **task** as completed")
    end
  end

  describe '.resolve_all_discussions' do
    let(:noteable) { create(:merge_request, source_project: project, target_project: project) }

    subject { described_class.resolve_all_discussions(noteable, project, author) }

    it_behaves_like 'a system note' do
      let(:action) { 'discussion' }
    end

    it 'sets the note text' do
      expect(subject.note).to eq 'resolved all discussions'
    end
  end

  describe '.diff_discussion_outdated' do
    let(:discussion) { create(:diff_note_on_merge_request).to_discussion }
    let(:merge_request) { discussion.noteable }
    let(:project) { merge_request.source_project }
    let(:change_position) { discussion.position }

    def reloaded_merge_request
      MergeRequest.find(merge_request.id)
    end

    subject { described_class.diff_discussion_outdated(discussion, project, author, change_position) }

    it_behaves_like 'a system note' do
      let(:expected_noteable) { discussion.first_note.noteable }
      let(:action)            { 'outdated' }
    end

    it 'creates a new note in the discussion' do
      # we need to completely rebuild the merge request object, or the `@discussions` on the merge request are not reloaded.
      expect { subject }.to change { reloaded_merge_request.discussions.first.notes.size }.by(1)
    end

    it 'links to the diff in the system note' do
      expect(subject.note).to include('version 1')

      diff_id = merge_request.merge_request_diff.id
      line_code = change_position.line_code(project.repository)
      expect(subject.note).to include(diffs_project_merge_request_url(project, merge_request, diff_id: diff_id, anchor: line_code))
    end
  end
end
