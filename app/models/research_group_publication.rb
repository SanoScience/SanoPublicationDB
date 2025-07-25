class ResearchGroupPublication < ApplicationRecord
    belongs_to :publication

    enum :research_group, {
        clinical_data_science: "Clinical Data Science",
        computational_neuroscience: "Computational Neuroscience",
        extreme_scale: "Extreme-Scale Data and Computing",
        modelling_simulation: "Modelling and Simulation",
        scientific_programmers: "Scientific Programmers",
        medical_imaging_robotics: "Medical Imaging and Robotics",
        personal_health_ds: "Personal Health Data Science",
        senior_post_doc: "SeniorPostDoc",
        genomics: "Structural and Functional Genomics Group",
        other: "other"
    }

    validates :publication, presence: true
    validates :research_group, presence: true

    def self.ransackable_attributes(auth_object = nil)
        ["research_group"]
    end

    def self.ransackable_associations(auth_object = nil)
        ["publication"]
    end
end
