class Publication < ApplicationRecord
    belongs_to :journal_issue, optional: true
    belongs_to :conference, optional: true
    has_many :identifiers, dependent: :destroy
    has_many :repository_links, dependent: :destroy
    has_many :research_group_publications, dependent: :destroy, inverse_of: :publication
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
    validates :link, format: { with: URI::DEFAULT_PARSER.make_regexp, message: "must be a valid URL" }, allow_nil: true
    validates_associated :research_group_publications,
                         :identifiers,
                         :repository_links,
                         :kpi_reporting_extension,
                         :open_access_extension,
                         :conference,
                         :journal_issue
end
