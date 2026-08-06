module Integrations
  class OpenalexMailer < ApplicationMailer
    default from: ENV["OUTLOOK_USERNAME"]

    def refresh_success(result)
      recipients = moderator_emails
      return if recipients.empty?

      subject_status = result.budget_exceeded ? "Success (Budget Exceeded Warning)" : "Success"

      mail(
        to: recipients,
        subject: "[PubDB] OpenAlex Refresh: #{subject_status}",
        body: success_body(result),
        content_type: "text/plain; charset=UTF-8"
      )
    end

    def refresh_failure(stage:, error:, started_at:)
      recipients = moderator_emails
      return if recipients.empty?

      mail(
        to: recipients,
        subject: "[PubDB] OpenAlex Refresh FAILED at stage: #{stage}",
        body: failure_body(stage: stage, error: error, started_at: started_at),
        content_type: "text/plain; charset=UTF-8"
      )
    end

    private

    def success_body(result)
      duration = (result.finished_at - result.started_at).round(2)

      budget_warning = if result.budget_exceeded
        "\nWARNING: Daily budget limit was reached. Some publications missing exact IDs were skipped.\n"
      else
        ""
      end

      failed_section = build_failed_section(result.failed_publications)

      <<~TEXT
        OpenAlex citations refresh workflow completed successfully.
        #{budget_warning}
        Processed publications: #{result.processed_count}
        Paid fallbacks used: #{result.fallbacks_used} / #{Integrations::Openalex::RefreshCitationsWorkflow::MAX_FALLBACKS_PER_RUN}

        Started at: #{result.started_at}
        Finished at: #{result.finished_at}
        Duration: #{duration} s
        #{failed_section}
      TEXT
    end

    def build_failed_section(failed_publications)
      return "\n\nAll publications were processed successfully." if failed_publications.empty?

      limit = 50
      lines = failed_publications.first(limit).map do |fp|
        "- [#{fp[:id]}] #{fp[:reason]} | #{fp[:title]&.truncate(50)}"
      end

      omitted = failed_publications.size - limit
      lines << "...and #{omitted} more" if omitted > 0

      "\n\nFailed / Skipped Publications (#{failed_publications.size}):\n#{lines.join("\n")}"
    end

    def failure_body(stage:, error:, started_at:)
      backtrace = Array(error.backtrace).first(10).join("\n")

      <<~TEXT
        OpenAlex citations refresh workflow failed.

        Stage: #{stage}
        Started at: #{started_at}
        Error class: #{error.class}
        Error message: #{error.message}

        Backtrace:
        #{backtrace}
      TEXT
    end
  end
end
