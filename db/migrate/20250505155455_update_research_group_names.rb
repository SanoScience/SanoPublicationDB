class UpdateResearchGroupNames < ActiveRecord::Migration[8.0]
  def up
    ResearchGroupPublication.where(research_group: "Computer Vision").update_all(research_group: "Computational Neuroscience")
    ResearchGroupPublication.where(research_group: "Health Informatics Group").update_all(research_group: "Medical Imaging and Robotics")
  end

  def down
    ResearchGroupPublication.where(research_group: "Computational Neuroscience").update_all(research_group: "Computer Vision")
    ResearchGroupPublication.where(research_group: "Medical Imaging and Robotics").update_all(research_group: "Health Informatics Group")
  end
end
