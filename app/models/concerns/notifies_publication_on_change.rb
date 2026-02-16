module NotifiesPublicationOnChange
    extend ActiveSupport::Concern

    included do
      after_save    :bubble_changes_to_publication
      after_destroy :bubble_destroy_to_publication
    end

    private

    IGNORE = %w[id created_at updated_at publication_id].freeze

    def bubble_changes_to_publication
      return unless respond_to?(:publication) && publication

      changes = previous_changes.except(*IGNORE)
      return if changes.blank?

      publication.__aggregate_child_change!(self.class.name, id, :updated, changes)
    end

    def bubble_destroy_to_publication
      return unless respond_to?(:publication) && publication

      publication.__aggregate_child_change!(self.class.name, id, :destroyed, {})
    end
end
