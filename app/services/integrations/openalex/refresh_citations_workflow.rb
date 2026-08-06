require "fileutils"

module Integrations
  module Openalex
    class RefreshCitationsWorkflow
      MAX_FALLBACKS_PER_RUN = 500
      REQUEST_DELAY = 0.3

      Result = Struct.new(
        :processed_count,
        :fallbacks_used,
        :budget_exceeded,
        :failed_publications,
        :started_at,
        :finished_at,
        keyword_init: true
      )

      def self.call
        new.call
      end

      def call
        started_at = Time.current
        stage = :initialization

        processed_count = 0
        fallbacks_used = 0
        budget_exceeded = false

        stage = :processing
        stats = process_publications!

        processed_count = stats[:processed_count]
        fallbacks_used = stats[:fallbacks_used]
        budget_exceeded = stats[:budget_exceeded]
        failed_publications = stats[:failed_publications]

        finished_at = Time.current

        stage = :success_marker
        write_success_marker!(finished_at)

        result = Result.new(
          processed_count: processed_count,
          fallbacks_used: fallbacks_used,
          budget_exceeded: budget_exceeded,
          failed_publications: failed_publications,
          started_at: started_at,
          finished_at: finished_at
        )

        stage = :success_email
        Integrations::OpenalexMailer.refresh_success(result)&.deliver_now!

        result
      rescue => e
        notify_failure(stage: stage, error: e, started_at: started_at)
        raise
      end

      private

      def process_publications!
        updater = Integrations::Openalex::CitationUpdater.new
        fallbacks = 0
        budget_exceeded = false
        processed = 0
        failed_pubs = []

        Publication.find_each do |publication|
          can_fallback = !budget_exceeded && fallbacks < MAX_FALLBACKS_PER_RUN
          has_id = has_exact_identifier?(publication)

          if !has_id && !can_fallback
            failed_pubs << { id: publication.id, title: publication.title, reason: "Skipped (Budget/Limits reached)" }
            next
          end

          begin
            success, error_msg, used_fallback = updater.call(publication, allow_fallback: can_fallback)

            fallbacks += 1 if used_fallback

            if success
              processed += 1
            else
              failed_pubs << { id: publication.id, title: publication.title, reason: error_msg }
            end

            sleep(REQUEST_DELAY)
          rescue Integrations::Openalex::Client::BudgetExceededError => e
            Rails.logger.warn("[RefreshCitationsWorkflow] Budget Exceeded: #{e.message}")
            budget_exceeded = true
            failed_pubs << { id: publication.id, title: publication.title, reason: "Triggered Budget Error" }
          end
        end

        {
          processed_count: processed,
          fallbacks_used: fallbacks,
          budget_exceeded: budget_exceeded,
          failed_publications: failed_pubs
        }
      end

      def has_exact_identifier?(publication)
        publication.identifiers.any? { |id| %w[openalex doi].include?(id.category.to_s) }
      end

      def write_success_marker!(time)
        marker = Rails.root.join("tmp", "last_openalex_refresh_success_at")
        FileUtils.mkdir_p(marker.dirname)
        File.write(marker, time.to_i.to_s)
      end

      def notify_failure(stage:, error:, started_at:)
        Integrations::OpenalexMailer.refresh_failure(
          stage: stage,
          error: error,
          started_at: started_at
        )&.deliver_now
      rescue => mail_error
        Rails.logger.error(
          "[RefreshCitationsWorkflow] failure email could not be sent. " \
          "original_error=#{error.class}: #{error.message}; " \
          "mailer_error=#{mail_error.class}: #{mail_error.message}"
        )
      end
    end
  end
end
