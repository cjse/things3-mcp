# frozen_string_literal: true

module Things3Mcp
  # Runs generated AppleScript against Things and returns plain Ruby data.
  class Client
    Generator = AppleScript::Generator

    def initialize(executor, date_parser)
      @executor = executor
      @date_parser = date_parser
    end

    # -- tasks -----------------------------------------------------------------

    def list_tasks(list: nil, project: nil, area: nil, tag: nil, search: nil, status: nil, limit: nil)
      tasks(Generator::Tasks.list_script(list: list, project: project, area: area, tag: tag,
                                         search: search, status: status, limit: limit))
    end

    def get_task(ref)
      task(Generator::Tasks.get_script(ref))
    end

    def add_task(title:, notes: nil, project: nil, area: nil, list: nil, tags: nil, due_date: nil, start_date: nil)
      task(Generator::Tasks.add_script(name: title, notes: notes, project: project, area: area, list: list,
                                       tags: tags, due_date: date(due_date), start_date: date(start_date)))
    end

    def update_task(ref, title: nil, notes: nil, project: nil, area: nil, list: nil, tags: nil,
                    due_date: nil, start_date: nil, status: nil)
      task(Generator::Tasks.update_script(ref, name: title, notes: notes, project: project, area: area, list: list,
                                          tags: tags, due_date: date(due_date), start_date: date(start_date),
                                          status: status))
    end

    def complete_task(ref)
      task(Generator::Tasks.complete_script(ref))
    end

    def delete_task(ref)
      task(Generator::Tasks.delete_script(ref))
    end

    def move_task(ref, destination:, destination_type:)
      task(Generator::Tasks.move_script(ref, destination: destination, destination_type: destination_type))
    end

    # -- projects --------------------------------------------------------------

    def list_projects(area: nil, status: nil, tag: nil, search: nil, limit: nil)
      projects(Generator::Projects.list_script(area: area, status: status, tag: tag, search: search, limit: limit))
    end

    def get_project(ref, include_tasks: true)
      record = project(Generator::Projects.get_script(ref))
      record[:tasks] = tasks(Generator::Projects.tasks_script(record[:id])) if include_tasks
      record
    end

    def add_project(name:, notes: nil, area: nil, tags: nil, due_date: nil, start_date: nil)
      project(Generator::Projects.add_script(name: name, notes: notes, area: area, tags: tags,
                                             due_date: date(due_date), start_date: date(start_date)))
    end

    def update_project(ref, name: nil, notes: nil, area: nil, tags: nil, due_date: nil, start_date: nil, status: nil)
      project(Generator::Projects.update_script(ref, name: name, notes: notes, area: area, tags: tags,
                                                due_date: date(due_date), start_date: date(start_date),
                                                status: status))
    end

    def delete_project(ref)
      project(Generator::Projects.delete_script(ref))
    end

    # -- areas -----------------------------------------------------------------

    def list_areas
      areas(Generator::Areas.list_script)
    end

    def add_area(name:, tags: nil)
      area(Generator::Areas.add_script(name: name, tags: tags))
    end

    def update_area(ref, name: nil, tags: nil)
      area(Generator::Areas.update_script(ref, name: name, tags: tags))
    end

    def delete_area(ref)
      area(Generator::Areas.delete_script(ref))
    end

    # -- tags ------------------------------------------------------------------

    def list_tags
      tags(Generator::Tags.list_script)
    end

    def add_tag(name:, parent: nil)
      tag(Generator::Tags.add_script(name: name, parent: parent))
    end

    def update_tag(ref, name: nil, parent: nil)
      tag(Generator::Tags.update_script(ref, name: name, parent: parent))
    end

    def delete_tag(ref)
      tag(Generator::Tags.delete_script(ref))
    end

    private

    def date(input)
      @date_parser.parse_natural_date(input)
    end

    def run(script)
      @executor.execute(script)
    end

    def tasks(script) = RecordParser.parse_many(run(script), Generator::Common::TASK_FIELDS)
    def task(script) = RecordParser.parse_one(run(script), Generator::Common::TASK_FIELDS)
    def projects(script) = RecordParser.parse_many(run(script), Generator::Common::PROJECT_FIELDS)
    def project(script) = RecordParser.parse_one(run(script), Generator::Common::PROJECT_FIELDS)
    def areas(script) = RecordParser.parse_many(run(script), Generator::Common::AREA_FIELDS)
    def area(script) = RecordParser.parse_one(run(script), Generator::Common::AREA_FIELDS)
    def tags(script) = RecordParser.parse_many(run(script), Generator::Common::TAG_FIELDS)
    def tag(script) = RecordParser.parse_one(run(script), Generator::Common::TAG_FIELDS)
  end
end
