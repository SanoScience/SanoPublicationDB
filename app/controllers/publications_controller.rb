class PublicationsController < ApplicationController
  def index
    @publications = Publication.all
  end

  def new
    @publication = Publication.new
  end

  def create
    @publication = Publication.new(publication_params)

    if publication_params[:conference_attributes][:name]&.present?
      conference = Conference.new(publication_params[:conference_attributes])
      
      if conference.save
        @publication.conference = conference
      else
        conference.errors.full_messages.each do |message|
          @publication.errors.add(:base, "Conference error: #{message}")
        end
        render :new, status: :unprocessable_entity
        return
      end
    elsif publication_params[:conference_id].present? && publication_params[:conference_id] != "0"
      conference = Conference.find(publication_params[:conference_id])
      @publication.conference = conference
    end

    if publication_params[:journal_issue_attributes][:title]&.present?
      journal_issue = JournalIssue.new(publication_params[:journal_issue_attributes])
      
      if journal_issue.save
        @publication.journal_issue = journal_issue
      else
        journal_issue.errors.full_messages.each do |message|
          @publication.errors.add(:base, "Journal issue error: #{message}")
        end
        render :new, status: :unprocessable_entity
        return
      end
    elsif publication_params[:journal_issue_id].present? && publication_params[:journal_issue_id] != "0"
      journal_issue = JournalIssue.find(publication_params[:journal_issue_id])
      @publication.journal_issue = journal_issue
    end

    if @publication.save
      redirect_to @publication, notice: 'Publication was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @publication = Publication.find(params[:id])
  end

  def edit
    @publication = Publication.find(params[:id])
  end

  def update
    @publication = Publication.find(params[:id])
    
    if publication_params[:conference_id].present? && publication_params[:conference_id] != "0"
      conference = Conference.find(publication_params[:conference_id])
      @publication.conference = conference
    else
      conference = Conference.new(publication_params[:conference_attributes])
      if conference.attributes.present? && conference.attributes != @publication.conference.attributes
        @publication.conference.update(conference.attributes)
        if !conference.save
          conference.errors.full_messages.each do |message|
            @publication.errors.add(:base, "Conference error: #{message}")
          end
          render :edit, status: :unprocessable_entity
          return
        end
      end
    end

    if publication_params[:journal_issue_id].present? && publication_params[:journal_issue_id] != "0"
      journal_issue = JournalIssue.find(publication_params[:journal_issue_id])
      @publication.journal_issue = journal_issue
    else
      journal_issue = JournalIssue.new(publication_params[:journal_issue_attributes])
      if journal_issue.attributes.present? && journal_issue.attributes != @publication.journal_issue.attributes
        @publication.journal_issue.update(journal_issue.attributes)
        if !journal_issue.save
          journal_issue.errors.full_messages.each do |message|
            @publication.errors.add(:base, "Journal issue error: #{message}")
          end
          render :edit, status: :unprocessable_entity
          return
        end
      end
    end

    if @publication.update(publication_params)
      redirect_to @publication, notice: 'Publication was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @publication = Publication.find(params[:id])
    @publication.destroy
    
    redirect_to publications_path, notice: "Publication was successfully deleted."
  end

  private

  def publication_params
    params.require(:publication).permit(
      :title, :category, :status, :author_list, :publication_date, :link,
      :conference_id, :journal_issue_id,
      research_group_publications_attributes: [:id, :research_group, :is_primary, :_destroy],
      identifiers_attributes: [:id, :category, :value, :_destroy],
      repository_links_attributes: [:id, :repository, :value, :_destroy],
      kpi_reporting_extension_attributes: [:id, :teaming_reporting_period, :invoice_number, :pbn, :jcr, :is_added_ft_portal, :is_checked, :is_new_method_technique, :is_methodology_application, :is_polish_med_researcher_involved, :subsidy_points, :_destroy],
      open_access_extension_attributes: [:id, :category, :gold_oa_charges, :gold_oa_funding_source, :_destroy],
      conference_attributes: [:id, :name, :core, :start_date, :end_date, :_destroy],
      journal_issue_attributes: [:id, :title, :journal_num, :publisher, :volume, :impact_factor, :_destroy]
    )
  end
end
