module Integrations
  module Openalex
    class CitationUpdater
      SOURCE_NAME = "OpenAlex".freeze

      def initialize(client: Integrations::Openalex::Client.new)
        @client = client
      end

      def call(publication, allow_fallback: false)
        work_data, used_fallback = fetch_work_data(publication, allow_fallback: allow_fallback)
        return [false, "Publication not found in OpenAlex", used_fallback] unless work_data

        save_citation_count!(publication, work_data)
        save_openalex_id!(publication, work_data)

        [true, nil, used_fallback]
      rescue Integrations::Openalex::Client::BudgetExceededError => e
        raise e
      rescue Integrations::Openalex::Client::Error, StandardError => e
        Rails.logger.error("OpenAlex CitationUpdater Error [Publication ID: #{publication.id}]: #{e.message}")
        [false, e.message, used_fallback || false]
      end

      private

      def fetch_work_data(publication, allow_fallback:)
        work_data = nil
        used_fallback = false

        if (openalex_id = identifier_value(publication, "openalex"))
          begin
            work_data = @client.work_by_openalex_id(openalex_id, select: Integrations::Openalex::Client::CITATION_SELECT)
          rescue Integrations::Openalex::Client::NotFoundError
            work_data = nil
            Rails.logger.debug("OpenAlex: ID #{openalex_id} not found, falling back")
          end
        end

        if !work_data && (doi = identifier_value(publication, "doi"))
          begin
            work_data = @client.work_by_doi(doi, select: Integrations::Openalex::Client::CITATION_SELECT)
          rescue Integrations::Openalex::Client::NotFoundError
            work_data = nil
            Rails.logger.debug("OpenAlex: DOI #{doi} not found or invalid, falling back to title")
          end
        end

        if !work_data && allow_fallback && publication.title.present?
          used_fallback = true
          response = @client.title_candidates(publication.title, select: Integrations::Openalex::Client::METADATA_SELECT)
          work_data = response&.dig("results")&.first

          if work_data.nil?
            Rails.logger.info("OpenAlex: Publication not found by title, skipping [Publication ID: #{publication.id}]")
          end
        end

        [work_data, used_fallback]
      end

      def identifier_value(publication, category_name)
        publication.identifiers.find { |id| id.category.to_s == category_name }&.value
      end

      def save_citation_count!(publication, work_data)
        count = work_data["cited_by_count"].to_i
        
        last_count = publication.citation_counts.where(source: SOURCE_NAME).order(recorded_at: :desc).first
        
        if last_count && last_count.recorded_at.to_date == Date.current
          last_count.update!(count: count)
        else
          publication.citation_counts.create!(
            source: SOURCE_NAME,
            count: count,
            recorded_at: Time.current
          )
        end
      end

      def save_openalex_id!(publication, work_data)
        return if identifier_value(publication, "openalex")
        
        new_id = work_data["id"]
        return unless new_id

        clean_id = new_id.split("/").last

        publication.identifiers.create!(
          category: "openalex",
          value: clean_id
        )
      end
    end
  end
end
