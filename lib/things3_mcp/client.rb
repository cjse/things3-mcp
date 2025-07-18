# frozen_string_literal: true

module Things3Mcp
  class Client
    def initialize(applescript_executor, date_parser, debug: false)
      @applescript_executor = applescript_executor
      @date_parser = date_parser
      @debug = debug
    end

    def add_task(args)
      title = args[:title] || args["title"]
      notes = args[:notes] || args["notes"]
      project = args[:project] || args["project"]
      area = args[:area] || args["area"]
      due_date = @date_parser.parse_natural_date(args[:due_date] || args["due_date"]) if args[:due_date] || args["due_date"]
      start_date = @date_parser.parse_natural_date(args[:start_date] || args["start_date"]) if args[:start_date] || args["start_date"]
      deadline = @date_parser.parse_natural_date(args[:deadline] || args["deadline"]) if args[:deadline] || args["deadline"]
      tags = args[:tags] || args["tags"] || []

      script = AppleScript::Generator.add_task_script(
        name: title,
        notes: notes,
        project: project,
        area: area,
        due_date: due_date,
        start_date: start_date,
        tags: tags
      )

      result = @applescript_executor.execute(script)
      
      {
        content: [
          {
            type: "text",
            text: result.force_encoding('UTF-8').strip
          }
        ]
      }
    end

    def get_tasks(args)
      list_type = args[:list] || args["list"] || "today"
      project_filter = args[:project] || args["project"]
      area_filter = args[:area] || args["area"]
      tag_filter = args[:tag] || args["tag"]
      limit = args[:limit] || args["limit"]

      script = AppleScript::Generator.list_tasks_script(
        list_type: list_type,
        project_filter: project_filter,
        area_filter: area_filter,
        tag_filter: tag_filter,
        limit: limit
      )

      result = @applescript_executor.execute(script)
      
      {
        content: [
          {
            type: "text",
            text: result.force_encoding('UTF-8').strip
          }
        ]
      }
    end

    def update_task(args)
      task_id = args[:task_id] || args["task_id"]
      title = args[:title] || args["title"]
      notes = args[:notes] || args["notes"]
      project = args[:project] || args["project"]
      area = args[:area] || args["area"]
      due_date = @date_parser.parse_natural_date(args[:due_date] || args["due_date"]) if args[:due_date] || args["due_date"]
      start_date = @date_parser.parse_natural_date(args[:start_date] || args["start_date"]) if args[:start_date] || args["start_date"]
      deadline = @date_parser.parse_natural_date(args[:deadline] || args["deadline"]) if args[:deadline] || args["deadline"]
      tags = args[:tags] || args["tags"]

      script = AppleScript::Generator.update_task_script(
        task_id: task_id,
        title: title,
        notes: notes,
        project: project,
        area: area,
        due_date: due_date,
        start_date: start_date,
        deadline: deadline,
        tags: tags
      )

      result = @applescript_executor.execute(script)
      
      {
        content: [
          {
            type: "text",
            text: result.force_encoding('UTF-8').strip
          }
        ]
      }
    end

    def complete_task(args)
      task_id = args[:task_id] || args["task_id"]
      
      script = AppleScript::Generator.complete_task_script(task_id: task_id)

      result = @applescript_executor.execute(script)
      
      {
        content: [
          {
            type: "text",
            text: result.force_encoding('UTF-8').strip
          }
        ]
      }
    end

    def delete_task(args)
      task_id = args[:task_id] || args["task_id"]
      
      script = AppleScript::Generator.delete_task_script(task_id: task_id)

      result = @applescript_executor.execute(script)
      
      {
        content: [
          {
            type: "text",
            text: result.force_encoding('UTF-8').strip
          }
        ]
      }
    end

    def move_task(args)
      task_id = args[:task_id] || args["task_id"]
      destination = args[:destination] || args["destination"]
      destination_type = args[:destination_type] || args["destination_type"]

      script = AppleScript::Generator.move_task_script(
        task_id: task_id,
        destination: destination,
        destination_type: destination_type
      )

      result = @applescript_executor.execute(script)
      
      {
        content: [
          {
            type: "text",
            text: result.force_encoding('UTF-8').strip
          }
        ]
      }
    end

    def escape_quotes(str)
      AppleScript::Generator.escape_quotes(str)
    end
  end
end