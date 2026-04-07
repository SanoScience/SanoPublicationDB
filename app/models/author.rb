class Author < ApplicationRecord
  include AuthorSearchSql

  has_many :publication_authorships, dependent: :destroy
  has_many :publications, -> { distinct }, through: :publication_authorships

  attr_accessor :author_type

  before_validation :normalize_author_fields

  validate :author_type_must_be_valid

  with_options if: :person? do
    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :collective_name, absence: true
  end

  with_options if: :collective? do
    validates :collective_name, presence: true
    validates :title, absence: true
    validates :first_name, absence: true
    validates :last_name, absence: true
  end

  scope :name_search, ->(term) do
    next all if term.blank?

    where(
      "#{normalized_author_name_sql('authors')} LIKE unaccent(lower(?))",
      normalized_like_pattern(term)
    )
  end

  scope :author_type_filter, ->(type) do
    case type.to_s
    when "person"
      where(collective_name: [ nil, "" ])
    when "collective"
      where.not(collective_name: [ nil, "" ])
    else
      all
    end
  end

  def person?
    resolved_author_type == "person"
  end

  def collective?
    resolved_author_type == "collective"
  end

  def display_name
    collective? ? collective_name : [ title, first_name, last_name ].reject(&:blank?).join(" ")
  end

  def publications_count
    self[:publications_count] || publications.size
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[first_name last_name collective_name title]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[publications publication_authorships]
  end

  def self.ransackable_scopes(_auth_object = nil)
    %i[name_search author_type_filter]
  end

  private

  def author_type_must_be_valid
    unless resolved_author_type.in?(%w[person collective])
      errors.add(:author_type, "is not included in the list")
    end
  end

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
  end
end
