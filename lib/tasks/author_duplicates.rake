namespace :authors do
  desc "Find suspected duplicate authors and email moderators"
  task report_duplicates: :environment do
    groups = Authors::DuplicateDetector.new.call

    if groups.any?
      DuplicateDetectorMailer.author_duplicates_report(groups)&.deliver_now
      puts "Duplicate author report sent: #{groups.count} group(s)"
    else
      puts "No suspected duplicate authors found"
    end
  end
end
