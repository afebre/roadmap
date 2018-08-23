require 'rails_helper'

RSpec.feature "Annotations::Editing", type: :feature do

  let!(:funder) { create(:org, :funder) }

  let!(:org) { create(:org, :school, :organisation) }

  let!(:template) { create(:template, :published, :publicly_visible, org: funder) }

  let!(:phase) { create(:phase, template: template) }

  let!(:section) { create(:section, phase: phase) }

  let!(:question) { create(:question, section: section) }

  let!(:annotation) do
    create(:annotation, question: question, org: org,
                        text: "Foo bar",type: "example_answer")
  end

  let!(:user) { create(:user, org: org) }

  before do
    create(:template, :default, :published)
    user.perms << create(:perm, :modify_templates)
    user.perms << create(:perm, :add_organisations)
    sign_in user
    visit org_admin_templates_path
  end

  scenario "Admin changes an Annotation of a draft Template", :js do
    click_link "Customisable Templates"
    within("#template_#{template.id}") do
      click_button "Actions"
    end
    expect {
      click_link "Customise"
    }.to change { Template.count }.by(1)

    click_link "Customise phase"
    click_link "Re-order sections"
    click_link section.title

    # NOTE: This is annotation 2, since Annotation was copied upon clicking "Customise"
    within("fieldset#fields_annotation_2") do
      tinymce_fill_in("question_annotations_attributes_annotation_2_text", "Noo bar")
    end
    # NOTE: This is question 2, since Annotation was copied upon clicking "Customise"
    within('#edit_question_2') do
      # Expect it to destroy the newly cleared Annotation
      expect { click_button 'Save' }.not_to change { Annotation.count }
    end
    expect(Annotation.find(1).text).to eql("Foo bar")
    expect(Annotation.find(2).text).to eql("Noo bar")
    expect(page).not_to have_errors
  end

  scenario "Admin sets a Template's question annotation to blank string", :js do
    click_link "Customisable Templates"
    within("#template_#{template.id}") do
      click_button "Actions"
    end
    expect {
      click_link "Customise"
    }.to change { Template.count }.by(1)

    click_link "Customise phase"
    click_link section.title
    # NOTE: This is annotation 2, since Annotation was copied upon clicking "Customise"
    within("fieldset#fields_annotation_2") do
      tinymce_fill_in("question_annotations_attributes_annotation_2_text", "")
    end
    # NOTE: This is question 2, since Annotation was copied upon clicking "Customise"
    within('#edit_question_2') do
      # Expect it to destroy the newly cleared Annotation
      expect { click_button 'Save' }.to change { Annotation.count }.by(-1)
    end
    expect(page).not_to have_errors
  end

end