class ExplorationController < Wicked::WizardController

  $experience_steps = {:research_experiences => :research,
                      :project_experiences => :project,
                      :teaching_experiences => :teaching,
                      :professional_experiences => :professional,
                      :related_experiences => :related}

  $activity_steps = {:student_activity_notes => :student,
                    :community_activity_notes => :community,
                    :hobby_activity_notes => :hobby}

  $generic_collection_class_mapper = {:test_scores => TestScore,
                                      :award_notes => AwardNote,
                                      :publications => Publication,
                                      :patents => Patent,
                                      :skill_notes => SkillNote,
                                      :languages => Language}

  # Steps in the Exploration flow
  # See https://github.com/schneems/wicked for Wicked documentation
  steps :preface,
    :contact_info,
    :education,
    :test_scores,
    :experiences_preface,
    *$experience_steps.keys,
    *$activity_steps.keys,
    :award_notes,
    :publications,
    :patents,
    :skill_notes,
    :languages,
    :user_defined_section,
    :resume_preview

  def show
    @user = current_user

    case step
    when :education
      if (@user.degrees.empty?)
        @user.degrees.create
      end
      @degrees = @user.degrees

    when :user_defined_section
      @other_section = current_user.other_section_note
      if !@other_section
        @other_section = current_user.create_other_section_note
      end

    when *$experience_steps.keys
      experience_type = $experience_steps[step]
      @experiences = @user.get_experiences(experience_type)

    when *$activity_steps.keys
      activity_type = $activity_steps[step]
      @activity_notes = @user.get_activities(activity_type)

    when *$generic_collection_class_mapper.keys
      @collection = get_generic_collection_for_step(step)

    when :resume_preview
      @degrees = @user.degrees
      @test_scores = @user.test_scores
      @research_experiences = @user.get_experiences(:research)
      @project_experiences = @user.get_experiences(:project)
      @teaching_experiences = @user.get_experiences(:teaching)
      @professional_experiences = @user.get_experiences(:professional)
      @related_experiences = @user.get_experiences(:related)
      @activity_notes = @user.activity_notes
      @award_notes = @user.award_notes
      @publications = @user.publications
      @patents = @user.patents
      @skill_notes = @user.skill_notes
      @languages = @user.languages
      @other_section = @user.other_section_note
    end

    render_wizard
  end

  def update
    ActionController::Parameters.permit_all_parameters = true
    @user = current_user

    case step
    when :contact_info
      @user.update_contact_info_params(params)

    when :user_defined_section
      other_section =
        OtherSectionNote.find(params[:other_section_note][:id])
      other_section.update_content(params)

    when *$experience_steps.keys
      if (!params[:experiences].nil?)
        Experience.update(params[:experiences].keys,
                          params[:experiences].values)
      end

    when *$activity_steps.keys
      if (!params[:activity_notes].nil?)
        ActivityNote.update(params[:activity_notes].keys,
                            params[:activity_notes].values)
      end

    when *$generic_collection_class_mapper.keys
      if (!params[step].nil?)
        class_obj = $generic_collection_class_mapper[step]
        class_obj.update(params[step].keys,
                         params[step].values)
      end
    end

    sign_in(@user, bypass: true) # needed for devise
    render_wizard @user
  end

  def destroy
    redirect_to exploration_path
  end

  def send_preview
    ResumePreviewMailer.resume_preview(current_user).deliver
    flash[:notice] = "已发送至你邮箱，请查阅"
    redirect_to :back
  end

  private

  def get_generic_collection_for_step(step)
    collection = current_user.send(step)
    if collection.empty? then collection.create end
    return collection
  end

end
