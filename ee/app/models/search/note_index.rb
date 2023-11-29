# frozen_string_literal: true

module Search
  class NoteIndex < Index
    self.allow_legacy_sti_class = true

    def self.indexed_class
      ::Note
    end
  end
end
