namespace :openalex_citations do
  desc "Refresh publication citations via OpenAlex workflow"
  task refresh: :environment do
    puts "Starting OpenAlex citation refresh workflow..."

    begin
      result = Integrations::Openalex::RefreshCitationsWorkflow.call

      puts "Citation refresh finished!"
      puts "Processed successfully: #{result.processed_count}"
      puts "Fallbacks used:       #{result.fallbacks_used}"

      if result.budget_exceeded
        puts "WARNING: OpenAlex budget was exceeded during the run."
      end

      if result.failed_publications.any?
        puts "Failed publications:  #{result.failed_publications.count}"
      end

    rescue => e
      puts "CRITICAL: Citation refresh workflow failed!"
      puts "Reason: #{e.class} - #{e.message}"

      raise
    end
  end
end
