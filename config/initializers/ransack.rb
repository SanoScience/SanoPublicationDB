Ransack.configure do |config|
    # accent- & case-insensitive contains
    config.add_predicate(
      'ucont',
      arel_predicate: 'ai_imatches',
      formatter: proc { |s| ActiveSupport::Inflector.transliterate("%#{s.to_s.tr(' ', '%')}%") },
      validator: proc { |s| s.present? },
      compounds: true,
      type: :string
    )
end