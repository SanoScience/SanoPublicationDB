require "test_helper"

class KpiReportingExtensionTest < ActiveSupport::TestCase
  def setup
    @kpi_reporting_extension = kpi_reporting_extensions("kpi1")
  end

  test "should be valid and saved with a publication" do
    assert @kpi_reporting_extension.valid?
    assert @kpi_reporting_extension.save
  end

  test "should require a publication" do
    @kpi_reporting_extension.publication = nil
    assert_not @kpi_reporting_extension.valid?
    assert_includes @kpi_reporting_extension.errors[:publication], "can't be blank"
  end

  test "should be destroyed when associated publication is destroyed" do
    publication = publications("pub1")
    publication.destroy
    
    assert_nil KpiReportingExtension.find_by(id: @kpi_reporting_extension.id)
  end
end
