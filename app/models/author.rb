class Author < ApplicationRecord
  has_many :publication_authorships, dependent: :destroy
  has_many :publications, through: :publication_authorships

  attr_accessor :author_type

  before_validation :normalize_author_fields

  validates :author_type, inclusion: { in: %w[person collective] }

  with_options if: :person_author? do
    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :collective_name, absence: true
  end

  with_options if: :collective_author? do
    validates :collective_name, presence: true
    validates :title, absence: true
    validates :first_name, absence: true
    validates :last_name, absence: true
  end

  def person_author?
    resolved_author_type == "person"
  end

  def collective_author?
    resolved_author_type == "collective"
  end

  def display_name
    collective_author? ? collective_name : [title, first_name, last_name].reject(&:blank?).join(" ")
  end

  private

  def resolved_author_type
    author_type.presence || inferred_author_type
  end

  def inferred_author_type
    collective_name.present? ? "collective" : "person"
  end

  def normalize_author_fields
    self.title = title.presence
    self.first_name = first_name.presence
    self.last_name = last_name.presence
    self.collective_name = collective_name.presence

    if collective_author?
      self.title = nil
      self.first_name = nil
      self.last_name = nil
    else
      self.collective_name = nil
    end
  end
end
