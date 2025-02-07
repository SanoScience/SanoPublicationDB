class Publication < ApplicationRecord
    belongs_to :journal_issue, optional: true
    # belongs_to :conference, optional: true
    has_many :identifiers, dependent: :destroy
    has_many :repository_links, dependent: :destroy
    has_many :research_group_publications, dependent: :destroy
  
    enum :type, {
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
    validates :type, presence: true, inclusion: { in: types.keys }
    validates :status, presence: true, inclusion: { in: statuses.keys }
    validates :author_list, presence: true
    validates :link, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp, message: "must be a valid URL" }
    
end