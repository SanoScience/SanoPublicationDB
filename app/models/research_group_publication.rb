class ResearchGroupPublication < ApplicationRecord
    belongs_to :publication

    enum :research_group, {
        clinical_data_science: "Clinical Data Science",
        computer_vision: "Computer Vision",
        extreme_scale: "Extreme-Scale Data and Computing",
        modelling_simulation: "Modelling and Simulation",
        scientific_programmers: "Scientific Programmers",
        health_informatics: "Health Informatics Group",
        personal_health_ds: "Personal Health Data Science",
        senior_post_doc: "SeniorPostDoc",
        genomics: "Structural and Functional Genomics Group",
        other: "other"
    }

    validates :publication, presence: true
    validates :research_group, presence: true
end
