module Api
  class OpenalexSearchController < ApplicationController
    before_action :authenticate_user!

    def show
      doi = params[:doi].to_s.strip
      
      if doi.blank?
        return render json: { error: "DOI parameter is required" }, status: :bad_request
      end

      client = Integrations::Openalex::Client.new
      work = client.work_by_doi(doi)

      render json: map_openalex_data(work), status: :ok

    rescue Integrations::Openalex::Client::NotFoundError => e
      render json: { error: e.message }, status: :not_found
    rescue Integrations::Openalex::Client::BudgetExceededError => e
      render json: { error: e.message }, status: :too_many_requests
    rescue StandardError => e
      render json: { error: "An unexpected error occurred: #{e.message}" }, status: :internal_server_error
    end

    private

    def map_openalex_data(work)
      {
        title: work["title"],
        publication_year: work["publication_year"],
        link: work.dig("primary_location", "landing_page_url") || work["doi"],
        category: map_category(work["type"]),
        status: map_status(work),
        identifiers: extract_identifiers(work),
        open_access: extract_open_access(work),
        authors: extract_authors(work["authorships"]),
        journal: extract_journal(work),
        conference: extract_conference(work)
      }
    end

    def map_category(openalex_type)
      case openalex_type
        when "article" then "journal_article" 
        when "proceedings-article" then "conference_manuscript"
        when "book-chapter" then "book_chapter"
        when "book" then "book"
        else nil
      end
    end

    def map_status(work)
      return nil if work["type"] == "preprint"

      if work["publication_date"].present? || work["publication_year"].present?
        "printed"
      else
        nil
      end
    end

    def extract_identifiers(work)
      identifiers = []
      
      allowed_categories = Identifier.categories.keys

      if work["ids"].is_a?(Hash)
        work["ids"].each do |raw_key, url|
          category_key = raw_key.downcase
          next if %w[doi openalex].include?(category_key)

          final_category = allowed_categories.include?(category_key) ? category_key : "other"
          
          id_value = url.split("/").last 

          final_value = final_category == "other" ? "#{category_key}:#{id_value}" : id_value

          identifiers << { 
            category: final_category, 
            value: final_value 
          }
        end
      end

      if work["doi"].present?
        identifiers << { 
          category: "doi", 
          value: extract_clean_doi(work["doi"]) 
        }
      end

      if work["id"].present?
        identifiers << { 
          category: "openalex", 
          value: extract_openalex_id(work["id"]) 
        }
      end

      source = work.dig("primary_location", "source")
      if source && source["issn"].is_a?(Array)
        source["issn"].each do |issn_val|
          identifiers << { 
            category: "issn", 
            value: issn_val 
          }
        end
      end

      identifiers
    end

    def extract_open_access(work)
      oa_data = work["open_access"]
      return nil unless oa_data && oa_data["is_oa"]

      raw_status = oa_data["oa_status"]&.downcase
      
      allowed_statuses = OpenAccessExtension.categories.keys

      return nil unless allowed_statuses.include?(raw_status)

      {
        is_oa: true,
        status: raw_status
      }
    end

    def extract_authors(authorships)
      return [] unless authorships.is_a?(Array)

      raw_authors = authorships.map do |authorship|
        { "display_name" => authorship.dig("author", "display_name") }
      end

      Authors::OpenalexMatcher.match(raw_authors)
    end

    def extract_clean_doi(doi_url)
      return nil if doi_url.blank?
      doi_url.sub("https://doi.org/", "doi:")
    end

    def extract_openalex_id(url)
      return nil if url.blank?
      url.sub("https://openalex.org/", "")
    end

    def extract_journal(work)
      source = work.dig("primary_location", "source") || {}
      biblio = work["biblio"] || {}
      raw_type = work.dig("primary_location", "raw_type")
      
      is_journal = work["type"] == "article" || 
                   source["type"] == "journal" || 
                   raw_type == "journal-article"
      return nil unless is_journal

      title = source["display_name"] || work.dig("primary_location", "raw_source_name")
      return nil if title.blank?

      volume = biblio["volume"]
      
      existing_journal = JournalIssue.where("lower(TRIM(title)) = ?", title.to_s.strip.downcase)
                                     .where(volume: volume)
                                     .first

      if existing_journal
        {
          match_type: "existing",
          id: existing_journal.id,
          title: existing_journal.title,
          volume: existing_journal.volume
        }
      else
        {
          match_type: "new",
          title: title,
          publisher: source["host_organization_name"] || source["publisher"],
          volume: volume,
          journal_num: biblio["issue"]
        }
      end
    end

    def extract_conference(work)
      source = work.dig("primary_location", "source") || {}
      raw_type = work.dig("primary_location", "raw_type")

      is_conf = work["type"] == "conference-paper" || 
                raw_type == "proceedings-article" || 
                source["type"] == "conference"

      return nil unless is_conf

      name = source["display_name"] || work.dig("primary_location", "raw_source_name")
      return nil if name.blank?

      existing_conf = Conference.where("lower(TRIM(name)) = ?", name.to_s.strip.downcase).first

      if existing_conf
        {
          match_type: "existing",
          id: existing_conf.id,
          name: existing_conf.name
        }
      else
        {
          match_type: "new",
          name: name
        }
      end
    end
  end
end