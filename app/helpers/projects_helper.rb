# A controller include, need to split out session methods
# verus those that aren't
module ProjectsHelper

  def self.project_tag(project)
    return nil if project.nil?
    project.name
  end

  def project_tag(project)
    ContentsHelper.content_tag(project)
  end

  def project_search_form
    render('/projects/quick_search_form')
  end

  def project_link(project)
    return nil if project.nil?
    l = link_to(project.name, select_project_path(project))
    project.id == sessions_current_project_id ?
      content_tag(:mark, l) :
      l 
  end

  def projects_list(projects)
    projects.collect{|p| content_tag(:li, project_link(p)) }.join.html_safe
  end

end
