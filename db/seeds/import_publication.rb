# to run use rails runner import_publication.rb file_path
# file_path - path to the csv file with publications

require 'csv'
require 'pp'

def import_publications(file_path)
  unless File.exist?(file_path)
    puts "Error: File not found - #{file_path}"
    return
  end

  CSV.foreach(file_path, headers: true, col_sep: ';', encoding: 'UTF-8') do |row|
    row = row.to_h.transform_keys { |key| key&.strip }

    title = row['Title of the scientific publication']&.strip
    next if title.blank?

    publication = Publication.find_or_initialize_by(title: title)
    file_publication_type = row[row.keys.first]&.strip

    category = case file_publication_type
    when "article in journal" then :journal_article
    when "conference manuscript" then :conference_manuscript
    when "book/monograph" then :book
    when "chapter book" then :book_chapter
    when "conference abstract" then :conference_abstract
    else nil
    end

    publication.assign_attributes(
      category: category,
      status: row['Status (submitted, accepted, printed)']&.strip,
      author_list: row['Authors']&.strip,
      publication_date: (Date.parse(row['Year of publication'].to_s) rescue nil),
      link: (row['Link']&.strip =~ URI.regexp ? row['Link'].strip : "https://unknown_url.com")
    )
    publication.save!


    # Handle Identifiers
    if row['Digital Object Identifier (DOI)'].present?
      publication.identifiers.find_or_create_by!(category: 'DOI', value: row['Digital Object Identifier (DOI)'].strip)
    end
    if row[' ISSN or eSSN'].present?
      publication.identifiers.find_or_create_by!(category: 'ISSN', value: row[' ISSN or eSSN'].strip)
    end

    # Handle Research Groups
    primary_group = row['Sano Research Group']&.strip
    secondary_groups = row['Secondary Sano Research Group(s)']&.split(',')&.map(&:strip).presence

    publication.research_group_publications.find_or_create_by!(
      research_group: primary_group,
      is_primary: true
    ) if primary_group.present?

    secondary_groups&.each do |group|
      publication.research_group_publications.create!(
        research_group: group,
        is_primary: false
      )
    end

    # Handle Open Access Extensions
    if row['OA: Green or Gold?'].present? && row['OA: Green or Gold?'].downcase != "no"
      if row['OA: Green or Gold?'].downcase == "green"
        OpenAccessExtension.find_or_create_by!(
          publication: publication,
          category: row['OA: Green or Gold?']&.strip
        )
      else
        OpenAccessExtension.find_or_create_by!(
          publication: publication,
          gold_oa_charges: row['For Gold OA: insert the amount of processing charges in PLN paid by SANO if any']&.to_f,
          gold_oa_funding_source: row['Funding source of OA']&.strip,
          category: row['OA: Green or Gold?']&.strip
        )
      end
    end

    # Handle Repository Links
    if row["Repository link':"].present?
      publication.repository_links.find_or_create_by!(
        repository: 'other',
        value: row["Repository link':"].strip
      )
    end

    # Handle KPI Reporting Extensions
    KpiReportingExtension.find_or_create_by!(
      publication: publication,
      teaming_reporting_period: row['Teaming Reporting Period']&.to_i,
      invoice_number: row['Invoice number']&.to_i,
      pbn: row['PBN']&.to_s&.downcase == 'yes',
      jcr: row['JCR']&.to_s&.downcase == 'yes',
      is_added_ft_portal: row['Added to F&T portal']&.to_s&.downcase == 'yes',
      is_checked: row['checked?']&.to_s&.downcase == 'yes',
      is_new_method_technique: row['Publications describing new methods and techniques (YES/NO)']&.to_s&.downcase == 'yes',
      is_methodology_application: row['Publications describing application of the methodology (YES/NO)']&.to_s&.downcase == 'yes',
      is_polish_med_researcher_involved: row['Polish medical researchers involved']&.to_s&.downcase == 'yes',
      subsidy_points: row['Subsidy points'].to_s.match?(/\A\d+\z/) ? row['Subsidy points'].to_i : nil,
      is_peer_reviewed: row['Peer-review']&.to_s&.downcase == 'yes'
    )
  end
end

# Run script with argument handling
if ARGV.empty?
  puts "Usage: ruby import_publications.rb <file_path>"
  exit(1)
end

file_path = ARGV.first
import_publications(file_path)
