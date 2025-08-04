class Publication < ApplicationRecord
    belongs_to :journal_issue, optional: true
    belongs_to :conference, optional: true
    has_many :identifiers, dependent: :destroy
    has_many :repository_links, dependent: :destroy
    has_many :research_group_publications, dependent: :destroy
    has_many :research_groups, through: :research_group_publications, class_name: "ResearchGroup"
    has_one :kpi_reporting_extension, dependent: :destroy
    has_one :open_access_extension, dependent: :destroy

    accepts_nested_attributes_for :research_group_publications, allow_destroy: true, reject_if: :all_blank
    accepts_nested_attributes_for :identifiers, allow_destroy: true, reject_if: :all_blank
    accepts_nested_attributes_for :repository_links, allow_destroy: true, reject_if: :all_blank
    accepts_nested_attributes_for :kpi_reporting_extension, allow_destroy: true, reject_if: :all_blank
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
    validate :link_must_be_valid_url
    validates_associated :research_group_publications,
                         :identifiers,
                         :repository_links,
                         :kpi_reporting_extension,
                         :open_access_extension,
                         :conference,
                         :journal_issue

    scope :with_research_groups, ->(groups) {
      joins(:research_group_publications)
        .where(research_group_publications: { research_group: groups })
        .distinct
    }

    def self.ransackable_attributes(auth_object = nil)
      [
        "title", "category", "status", "author_list", "publication_date", "publication_year",
        "research_group_publications_research_group_id_in",
        "identifiers_type", "identifiers_value",
        "journal_issue_title_cont",
        "conference_name_cont",
        "kpi_reporting_extension_teaming_reporting_period_eq", "kpi_reporting_extension_pbn_eq", "kpi_reporting_extension_jcr_eq",
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

    ransacker :publication_year, type: :integer do
      Arel.sql("EXTRACT(YEAR FROM publication_date)")
    end

    private

    def link_must_be_valid_url
      return if link.blank?
    
      uri = URI.parse(link)
    
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        errors.add(:link, "must be a valid HTTP/HTTPS URL")
      end
    rescue URI::InvalidURIError
      errors.add(:link, "must be a valid URL")
    end
end
