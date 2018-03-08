module API
  class Discussions < Grape::API
    include PaginationParams
    helpers ::API::Helpers::NotesHelpers

    before { authenticate! }

    NOTEABLE_TYPES = [Issue, Snippet].freeze

    NOTEABLE_TYPES.each do |noteable_type|
      parent_type = noteable_type.parent_class.to_s.underscore
      noteables_str = noteable_type.to_s.underscore.pluralize

      params do
        requires :id, type: String, desc: "The ID of a #{parent_type}"
      end
      resource parent_type.pluralize.to_sym, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
        desc "Get a list of #{noteable_type.to_s.downcase} discussions" do
          success Entities::Discussion
        end
        params do
          requires :noteable_id, type: Integer, desc: 'The ID of the noteable'
          use :pagination
        end
        get ":id/#{noteables_str}/:noteable_id/discussions" do
          noteable = find_noteable(parent_type, noteables_str, params[:noteable_id])

          return not_found!("Discussions") unless can?(current_user, noteable_read_ability_name(noteable), noteable)

          notes = noteable.notes
            .inc_relations_for_view
            .includes(:noteable)
            .fresh

          notes = notes.reject { |n| n.cross_reference_not_visible_for?(current_user) }
          discussions = Kaminari.paginate_array(Discussion.build_collection(notes, noteable))

          present paginate(discussions), with: Entities::Discussion
        end

        desc "Get a single #{noteable_type.to_s.downcase} discussion" do
          success Entities::Discussion
        end
        params do
          requires :discussion_id, type: String, desc: 'The ID of a discussion'
          requires :noteable_id, type: Integer, desc: 'The ID of the noteable'
        end
        get ":id/#{noteables_str}/:noteable_id/discussions/:discussion_id" do
          noteable = find_noteable(parent_type, noteables_str, params[:noteable_id])
          notes = readable_discussion_notes(noteable, params[:discussion_id])

          if notes.empty? || !can?(current_user, noteable_read_ability_name(noteable), noteable)
            return not_found!("Discussion")
          end

          discussion = Discussion.build(notes, noteable)

          present discussion, with: Entities::Discussion
        end

        desc "Create a new #{noteable_type.to_s.downcase} discussion" do
          success Entities::Discussion
        end
        params do
          requires :noteable_id, type: Integer, desc: 'The ID of the noteable'
          requires :body, type: String, desc: 'The content of a note'
          optional :created_at, type: String, desc: 'The creation date of the note'
        end
        post ":id/#{noteables_str}/:noteable_id/discussions" do
          noteable = find_noteable(parent_type, noteables_str, params[:noteable_id])

          opts = {
            note: params[:body],
            created_at: params[:created_at],
            type: 'DiscussionNote',
            noteable_type: noteables_str.classify,
            noteable_id: noteable.id
          }

          note = create_note(noteable, opts)

          if note.valid?
            present note.discussion, with: Entities::Discussion
          else
            bad_request!("Note #{note.errors.messages}")
          end
        end

        desc "Get comments in a single #{noteable_type.to_s.downcase} discussion" do
          success Entities::Discussion
        end
        params do
          requires :discussion_id, type: String, desc: 'The ID of a discussion'
          requires :noteable_id, type: Integer, desc: 'The ID of the noteable'
        end
        get ":id/#{noteables_str}/:noteable_id/discussions/:discussion_id/notes" do
          noteable = find_noteable(parent_type, noteables_str, params[:noteable_id])
          notes = readable_discussion_notes(noteable, params[:discussion_id])

          if notes.empty? || !can?(current_user, noteable_read_ability_name(noteable), noteable)
            return not_found!("Notes")
          end

          present notes, with: Entities::Note
        end

        desc "Add a comment to a #{noteable_type.to_s.downcase} discussion" do
          success Entities::Note
        end
        params do
          requires :noteable_id, type: Integer, desc: 'The ID of the noteable'
          requires :discussion_id, type: String, desc: 'The ID of a discussion'
          requires :body, type: String, desc: 'The content of a note'
          optional :created_at, type: String, desc: 'The creation date of the note'
        end
        post ":id/#{noteables_str}/:noteable_id/discussions/:discussion_id/notes" do
          noteable = find_noteable(parent_type, noteables_str, params[:noteable_id])
          notes = readable_discussion_notes(noteable, params[:discussion_id])

          return not_found!("Discussion") if notes.empty?
          return bad_request!("Discussion is an individual note.") unless notes.first.part_of_discussion?

          opts = {
            note: params[:body],
            type: 'DiscussionNote',
            in_reply_to_discussion_id: params[:discussion_id],
            created_at: params[:created_at]
          }
          note = create_note(noteable, opts)

          if note.valid?
            present note, with: Entities::Note
          else
            bad_request!("Note #{note.errors.messages}")
          end
        end

        desc "Get a comment in a #{noteable_type.to_s.downcase} discussion" do
          success Entities::Note
        end
        params do
          requires :noteable_id, type: Integer, desc: 'The ID of the noteable'
          requires :discussion_id, type: String, desc: 'The ID of a discussion'
          requires :note_id, type: Integer, desc: 'The ID of a note'
        end
        get ":id/#{noteables_str}/:noteable_id/discussions/:discussion_id/notes/:note_id" do
          noteable = find_noteable(parent_type, noteables_str, params[:noteable_id])

          get_note(noteable, params[:note_id])
        end

        desc "Edit a comment in a #{noteable_type.to_s.downcase} discussion" do
          success Entities::Note
        end
        params do
          requires :noteable_id, type: Integer, desc: 'The ID of the noteable'
          requires :discussion_id, type: String, desc: 'The ID of a discussion'
          requires :note_id, type: Integer, desc: 'The ID of a note'
          requires :body, type: String, desc: 'The content of a note'
        end
        put ":id/#{noteables_str}/:noteable_id/discussions/:discussion_id/notes/:note_id" do
          noteable = find_noteable(parent_type, noteables_str, params[:noteable_id])

          update_note(noteable, params[:note_id])
        end

        desc "Delete a comment in a #{noteable_type.to_s.downcase} discussion" do
          success Entities::Note
        end
        params do
          requires :noteable_id, type: Integer, desc: 'The ID of the noteable'
          requires :discussion_id, type: String, desc: 'The ID of a discussion'
          requires :note_id, type: Integer, desc: 'The ID of a note'
        end
        delete ":id/#{noteables_str}/:noteable_id/discussions/:discussion_id/notes/:note_id" do
          noteable = find_noteable(parent_type, noteables_str, params[:noteable_id])

          delete_note(noteable, params[:note_id])
        end
      end
    end

    helpers do
      def readable_discussion_notes(noteable, discussion_id)
        notes = noteable.notes
          .where(discussion_id: discussion_id)
          .inc_relations_for_view
          .includes(:noteable)
          .fresh

        notes.reject { |n| n.cross_reference_not_visible_for?(current_user) }
      end
    end
  end
end
