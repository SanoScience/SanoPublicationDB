module PublicationsConferenceSystemHelper
  def within_conference(&block)
    within(".conference", &block)
  end

  def select_conference(name)
    within_conference do
      find(".items-list select").select(name)
    end
  end

  def assert_conf_fields(name:, core:)
    within_conference do
      assert_field "Conference Name", with: name
      assert_field "CORE Ranking", with: core.to_s
    end
  end
end
