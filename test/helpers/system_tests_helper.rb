module SystemTestsHelper
   def ensure_required_kpi_selected!
    within ".kpi-reporting-extension" do
      %w[
        is_new_method_technique
        is_methodology_application
        is_polish_med_researcher_involved
        is_peer_reviewed
        is_co_publication_with_partners
      ].each do |attr|
        name = "publication[kpi_reporting_extension_attributes][#{attr}]"
        select_el = find("select[name='#{name}']", visible: :all)
        select_el.select("No") if select_el.value.blank?
      end
    end
  end

  def set_date_select(prefix, year:, month_name:, day:)
    find("select[name*='[#{prefix}(1i)]']").select(year.to_s)
    find("select[name*='[#{prefix}(2i)]']").select(month_name)
    find("select[name*='[#{prefix}(3i)]']").select(day.to_s)
  end
end
