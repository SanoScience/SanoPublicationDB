require "net/http"
require "json"
require "uri"

module Integrations
  module Openalex
    class Client
      BASE_URL = "https://api.openalex.org".freeze

      METADATA_SELECT = %w[
        id doi title display_name publication_year publication_date
        type ids primary_location biblio authorships open_access
        locations cited_by_count counts_by_year updated_date
      ].join(",").freeze

      CITATION_SELECT = %w[
        id doi cited_by_count counts_by_year updated_date
      ].join(",").freeze

      class Error < StandardError; end
      class NotFoundError < Error; end
      class BudgetExceededError < Error; end

      def initialize(
        api_key: ENV["OPENALEX_API_KEY"],
        mailto: ENV["OPENALEX_MAILTO"],
        timeout: 10,
        min_daily_budget_usd: 0.1
      )
        @api_key = api_key
        @mailto = mailto
        @timeout = timeout
        @min_daily_budget_usd = min_daily_budget_usd
      end

      def work_by_doi(doi, select: METADATA_SELECT)
        clean_doi_url = extract_clean_doi(doi)

        raise NotFoundError, "Invalid or missing DOI format in string: #{doi}" unless clean_doi_url

        get("/works/#{clean_doi_url}", select: select)
      end

      def work_by_openalex_id(openalex_id, select: METADATA_SELECT)
        get("/works/#{work_id(openalex_id)}", select: select)
      end

      def title_candidates(title, year: nil, type: nil, per_page: 10, select: METADATA_SELECT)
        ensure_budget_for!(:search)

        filters = [
          ("publication_year:#{year}" if year.present?),
          ("type:#{type}" if type.present?)
        ].compact.join(",")

        safe_title = normalize_title(title)
        return { "results" => [] } if safe_title.blank?

        response = get(
          "/works",
          search: safe_title,
          filter: filters.presence,
          "per-page": per_page,
          select: select
        )

        response["results"] = response["results"].select do |work|
          candidate_title = work["title"] || work["display_name"]
          titles_match?(safe_title, normalize_title(candidate_title))
        end

        response
      end

      def safe_rate_limit
        get("/rate-limit")
      rescue Error => e
        raise BudgetExceededError, "Cannot verify OpenAlex budget, paid request blocked: #{e.message}"
      end

      private

      def ensure_budget_for!(operation)
        return if @api_key.blank?

        status = safe_rate_limit["rate_limit"]
        return unless status.is_a?(Hash)

        daily_remaining = status.fetch("daily_remaining_usd", 0).to_f

        costs = status.fetch("endpoint_costs_usd", {})
        expected_cost = costs.fetch(operation.to_s, 0.01).to_f

        return if daily_remaining >= expected_cost + @min_daily_budget_usd

        raise BudgetExceededError,
              "OpenAlex daily budget too low: remaining $#{daily_remaining}, expected $#{expected_cost}, reserve $#{@min_daily_budget_usd}"
      end

      def get(path, params = {})
        uri = build_uri(path, params)

        response = Net::HTTP.start(
          uri.host,
          uri.port,
          use_ssl: uri.scheme == "https",
          open_timeout: @timeout,
          read_timeout: @timeout
        ) do |http|
          http.get(uri.request_uri)
        end

        parse_response(response)
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        raise Error, "OpenAlex timeout: #{e.message}"
      rescue SocketError => e
        raise Error, "OpenAlex connection error: #{e.message}"
      end

      def build_uri(path, params)
        uri = URI("#{BASE_URL}#{path}")

        query_params = params.compact

        query_params[:api_key] = @api_key if @api_key.present?
        query_params[:mailto] = @mailto if @mailto.present?

        uri.query = URI.encode_www_form(query_params) if query_params.any?
        uri
      end

      def parse_response(response)
        content_type = response["Content-Type"].to_s.downcase
        body_text = response.body.to_s.strip

        if content_type.include?("text/html") || body_text.start_with?("<")
          raise NotFoundError, "OpenAlex returned HTML instead of JSON (HTTP #{response.code})"
        end

        body = JSON.parse(body_text)

        case response
        when Net::HTTPSuccess
          body
        when Net::HTTPNotFound
          raise NotFoundError, body["message"] || "OpenAlex record not found"
        when Net::HTTPTooManyRequests
          raise BudgetExceededError, "OpenAlex API rate limit exceeded (429)"
        else
          raise Error, body["message"] || "OpenAlex error #{response.code}"
        end
      rescue JSON::ParserError
        raise Error, "Invalid JSON response from OpenAlex. Preview: #{body_text[0..100]}"
      end

      def extract_clean_doi(raw_string)
        return nil if raw_string.blank?

        match = raw_string.to_s.match(/(10\.\d{4,9}\/[^\s]+)/i)
        return nil unless match

        clean_doi = match[1]

        clean_doi = clean_doi.sub(/[.,;:\])]+$/, "")

        "https://doi.org/#{clean_doi.downcase}"
      end

      def titles_match?(target_norm, cand_norm)
        return true if target_norm == cand_norm

        target_words = target_norm.split.uniq
        cand_words = cand_norm.split.uniq

        min_length = [ target_words.size, cand_words.size ].min

        return false if min_length < 5

        return true if target_norm.include?(cand_norm) || cand_norm.include?(target_norm)

        intersection_count = (target_words & cand_words).size.to_f
        overlap_ratio = intersection_count / min_length

        overlap_ratio >= 0.8
      end

      def normalize_title(value)
        value.to_s.downcase.gsub(/[^\p{L}\p{N}]+/, " ").squeeze(" ").strip
      end

      def work_id(openalex_id)
        openalex_id.to_s.strip.split("/").last
      end
    end
  end
end
