# to run use rails runner import_publication.rb file_path
# file_path - path to the csv file with publications

require 'csv'
require 'pp'
require 'uri'

def import_publications(file_path)
  unless File.exist?(file_path)
    puts "Error: File not found - #{file_path}"
    return
  end

  # Remove carriage returns from the file
  content = File.read(file_path)
  cleaned_content = content.gsub("\r", "")
  puts "Removing carriage returns from CSV content"

  cleaned_content = cleaned_content.gsub(/(?:yes|no|checked\?|;)\n|\n/) { |match| match.end_with?("\n") ? (match.length > 1 ? match : " ") : match }
  puts "Removed redundant newlines"

  cleaned_content = cleaned_content.gsub("Structual", "Structural")
  cleaned_content = cleaned_content.gsub("\"", " ")
  puts "Removed \" from CSV content"

  CSV.parse(cleaned_content, headers: true, col_sep: ';', encoding: 'UTF-8').each do |row|
    row = row.to_h.transform_keys { |key| key&.strip }
    puts "\n"
    puts row

    title = row['Title of the scientific publication']&.strip
    authors = row['Authors']&.strip
    status = row['Status (submitted, accepted, printed)']&.strip
    publication_type = row[row.keys.first]&.strip
    next if title.blank? || authors.blank? || status.blank? || publication_type.blank?

    publication = Publication.find_or_initialize_by(title: title)

    category = case publication_type
    when "article in journal" then :journal_article
    when "conference manuscript" then :conference_manuscript
    when "book/monograph" then :book
    when "chapter book" then :book_chapter
    when "conference abstract" then :conference_abstract
    else nil
    end

    valid_url = ->(s) do
      return false if s.blank?
      u = URI.parse(s.strip)
      u.is_a?(URI::HTTP) && u.host.present?
    rescue URI::InvalidURIError
      false
    end

    publication.assign_attributes(
      category: category,
      status: status,
      author_list: authors,
      publication_year: (Integer(row['Year of publication']) rescue nil),
      link: (valid_url.call(row['Link']&.strip) ? row['Link']&.strip : nil)
    )
    publication.save!


    # Handle Identifiers
    if row['Digital Object Identifier (DOI)'].present?
      doi = row['Digital Object Identifier (DOI)']&.strip
      if doi =~ /\A10\.\S+/
        doi = "https://doi.org/#{doi}"
      elsif valid_url.call(doi)
        doi = doi
      end
      publication.identifiers.find_or_create_by!(category: 'DOI', value: doi) if !doi.blank?
    end
    # if row[' ISSN or eSSN'].present?
    #   publication.identifiers.find_or_create_by!(category: 'ISSN', value: row[' ISSN or eSSN'].strip)
    # end

    # Handle Research Groups
    primary_group_name = row['Sano Research Group']&.strip
    secondary_group_names = row['Secondary Sano Research Group(s)']&.split(',')&.map(&:strip).presence

    if primary_group_name.present?
      group = ResearchGroup.find_or_create_by!(name: primary_group_name)
      publication.research_group_publications.find_or_create_by!(
        research_group: group,
        is_primary: true
      )
    end

    secondary_group_names&.each do |name|
      next if name == primary_group_name # avoid duplication
      group = ResearchGroup.find_or_create_by!(name: name)
      publication.research_group_publications.find_or_create_by!(
        research_group: group,
        is_primary: false
      )
    end

    # Handle Open Access Extensions
    oa_raw  = row['OA: Green or Gold?']
    oa_kind = oa_raw.to_s.strip.downcase

    parse_money = ->(s) do
      return nil if s.blank?
      normalized = s.to_s.strip
                    .gsub(/[^\d,.\-]/, '')
                    .gsub(/\s+/, '')
      if normalized.include?(',') && normalized.include?('.')
        normalized = normalized.gsub(',', '')     # comma as thousands
      else
        normalized = normalized.tr(',', '.')      # comma as decimal
      end
      Float(normalized)
    rescue ArgumentError
      nil
    end

    case oa_kind
    when 'green'
      publication.create_open_access_extension!(
        category: :green,
        gold_oa_charges: nil,
        gold_oa_funding_source: nil
      )
    when 'gold'
      publication.create_open_access_extension!(
        category: :gold,
        gold_oa_charges: parse_money.call(row['For Gold OA: insert the amount of processing charges in PLN paid by SANO if any']),
        gold_oa_funding_source: row['Funding source of OA']&.strip&.presence
      )
    end

    # Handle Repository Links
    if row["Repository link':"].present?
      repository_link = (valid_url.call(row["Repository link':"]&.strip) ? row["Repository link':"]&.strip : nil)
      if repository_link.present?
        publication.repository_links.find_or_create_by!(
          repository: 'other',
          value: repository_link
        )
      end
    end

    # Handle KPI Reporting Extensions
    to_bool = ->(v) { v.to_s.strip.downcase == 'yes' }

    kpi = KpiReportingExtension.find_or_initialize_by(publication: publication)
    kpi.assign_attributes(
      teaming_reporting_period: row['Teaming Reporting Period']&.to_i,
      invoice_number: row['Invoice number']&.strip,
      pbn: to_bool.call(row['PBN']),
      jcr: to_bool.call(row['JCR']),
      is_added_ft_portal: to_bool.call(row['Added to F&T portal']),
      is_checked: to_bool.call(row['checked?']),
      is_new_method_technique: to_bool.call(row['Publications describing new methods and techniques (YES/NO)']),
      is_methodology_application: to_bool.call(row['Publications describing application of the methodology (YES/NO)']),
      is_polish_med_researcher_involved: to_bool.call(row['Polish medical researchers involved']),
      subsidy_points: row['Subsidy points'].to_s.match?(/\A\d+\z/) ? row['Subsidy points'].to_i : nil,
      is_peer_reviewed: to_bool.call(row['Peer-review']),
      is_co_publication_with_partners: to_bool.call(row['Co-publications with national and foreign partners [t]'])
    )
    kpi.save!

    # Handle Conference
    if row['Title of the journal or equivalent'].present?
      if publication.category == "conference_manuscript" || publication.category == "conference_abstract"
        conference = Conference.find_or_create_by!(name: row['Title of the journal or equivalent'].strip)
        publication.conference = conference
        if row['Impact Factor  or CORE  (in case of conference manuscripts)'].present? && row['Impact Factor  or CORE  (in case of conference manuscripts)'] != "nd"
          conference.core = row['Impact Factor  or CORE  (in case of conference manuscripts)']
        end
        conference.save!
        publication.save!
      elsif publication.category == "journal_article"
        journal = JournalIssue.find_or_create_by!(title: row['Title of the journal or equivalent'].strip)
        publication.journal_issue = journal
        if row['Impact Factor  or CORE  (in case of conference manuscripts)'].present?
          journal.impact_factor = row['Impact Factor  or CORE  (in case of conference manuscripts)'].to_f
        end
        if row['Publisher'].present?
          journal.publisher = row['Publisher']
        end
        journal.save!
        publication.save!
      end
    end
  end
end

# Run script with argument handling
if ARGV.empty?
  puts "Usage: ruby import_publications.rb <file_path>"
  exit(1)
end

file_path = ARGV.first
import_publications(file_path)
