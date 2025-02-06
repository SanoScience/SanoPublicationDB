class Publication < ApplicationRecord
    enum type: { 
    journal_article: 0, 
    conference_manuscript: 1, 
    book: 2, 
    book_chapter: 3, 
    conference_abstract: 4 
  }

  enum status: { 
    submitted: 0, 
    accepted: 1, 
    printed: 2 
  }

  validates :type, presence: true, inclusion: { in: types.keys }
  validates :status, presence: true, inclusion: { in: statuses.keys }
end
