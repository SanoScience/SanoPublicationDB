class Publication < ApplicationRecord
    include UrlValidatable
    validates_url_of :link

    belongs_to :journal_issue, optional: true
    belongs_to :conference, optional: true
    belongs_to :owner, class_name: "User", optional: true
    has_many :identifiers, dependent: :destroy
    has_many :repository_links, dependent: :destroy
    has_many :research_group_publications, dependent: :destroy
    has_many :research_groups, through: :research_group_publications, class_name: "ResearchGroup"
    has_one :kpi_reporting_extension, dependent: :destroy
    has_one :open_access_extension, dependent: :destroy

    accepts_nested_attributes_for :research_group_publications, allow_destroy: true, reject_if: :all_blank
    accepts_nested_attributes_for :identifiers, allow_destroy: true, reject_if: :all_blank
    accepts_nested_attributes_for :repository_links, allow_destroy: true, reject_if: :all_blank
    accepts_nested_attributes_for :kpi_reporting_extension, allow_destroy: true
    accepts_nested_attributes_for :open_access_extension, allow_destroy: true, reject_if: :all_blank
    accepts_nested_attributes_for :conference, allow_destroy: true, reject_if: :all_blank
    accepts_nested_attributes_for :journal_issue, allow_destroy: true, reject_if: :all_blank

    enum :category, {
      journal_article: 0,
      conference_manuscript: 1,
      book: 2,
      book_chapter: 3,
      conference_abstract: 4
    }

    enum :status, {
        submitted: 0,
        accepted: 1,
        printed: 2
    }

    validates :title, presence: true
    validates :category, presence: true, inclusion: { in: categories.keys }
    validates :status, presence: true, inclusion: { in: statuses.keys }
    validates :author_list, presence: true
    validates :publication_year,
              numericality: { only_integer: true, greater_than: 2000, less_than: Time.zone.today.year + 1 },
              allow_nil: true

    with_options on: :ui do
      validates :publication_year,
                presence: true,
                numericality: { only_integer: true, greater_than: 2000, less_than: Time.zone.today.year + 1 }
      validates :kpi_reporting_extension, presence: true
    end

    validates_associated :research_group_publications,
                         :identifiers,
                         :repository_links,
                         :kpi_reporting_extension,
                         :open_access_extension,
                         :conference,
                         :journal_issue

    attr_accessor :_notification_changes

    def __aggregate_child_change!(klass_name, record_id, action, changes)
      self._notification_changes ||= { publication: {}, children: [] }
      self._notification_changes[:children] << {
        model: klass_name, id: record_id, action: action, changes: changes
      }
    end

    scope :with_research_groups, ->(groups) {
      joins(:research_group_publications)
        .where(research_group_publications: { research_group: groups })
        .distinct
    }

    after_initialize do
      build_kpi_reporting_extension if new_record? && kpi_reporting_extension.nil?
    end

    def self.ransackable_attributes(auth_object = nil)
      [
        "title", "category", "status", "author_list", "publication_year",
        "research_group_publications_research_group_id_in",
        "identifiers_type", "identifiers_value",
        "journal_issue_title_cont",
        "conference_name_cont",
        "kpi_reporting_extension_teaming_reporting_period_eq", "kpi_reporting_extension_pbn_eq", "kpi_reporting_extension_jcr_eq",
        "kpi_reporting_extension_is_new_method_technique_eq", "kpi_reporting_extension_is_methodology_application_eq", "kpi_reporting_extension_is_peer_reviewed_eq",
        "open_access_extension_category_eq", "open_access_extension_gold_oa_funding_source_cont"
      ]
    end

    def self.ransackable_associations(auth_object = nil)
        [ "research_group_publications", "identifiers", "conference", "journal_issue", "kpi_reporting_extension", "open_access_extension" ]
    end

    ransacker :status, formatter: proc { |v| statuses[v] } do |parent|
      parent.table[:status]
    end

    ransacker :category, formatter: proc { |v| categories[v] } do |parent|
      parent.table[:category]
    end

  def build_notification_payload
    pub_changes = previous_changes.except("updated_at", "created_at", "id", "owner_id")
    children_changes = _notification_changes&.dig(:children) || []
    return if pub_changes.blank? && children_changes.blank?

    { publication: pub_changes.presence, children: children_changes.presence }.compact
  end
end
