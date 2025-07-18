require 'fast_mcp'

module Things3Mcp
  module Tools
    class UpdateTaskTool < FastMcp::Tool
      tool_name 'update_task'
      description "Update an existing task in Things 3"
      
      arguments do
        required(:task_id).filled(:string).description("Task ID or title to identify the task")
        optional(:title).filled(:string).description("New task title")
        optional(:notes).filled(:string).description("New task notes")
        optional(:project).filled(:string).description("New project name")
        optional(:area).filled(:string).description("New area name")
        optional(:tags).array(:string).description("New tags")
        optional(:due_date).filled(:string).description("New due date (natural language)")
        optional(:start_date).filled(:string).description("New start date (natural language)")
        optional(:deadline).filled(:string).description("New deadline (natural language)")
      end
      
      def call(task_id:, title: nil, notes: nil, project: nil, area: nil, tags: nil, due_date: nil, start_date: nil, deadline: nil)
        executor = AppleScript::Executor.new(debug: false)
        date_parser = DateParser.new(debug: false)
        client = Client.new(executor, date_parser, debug: false)
        
        result = client.update_task({
          task_id: task_id,
          title: title,
          notes: notes,
          project: project,
          area: area,
          tags: tags,
          due_date: due_date,
          start_date: start_date,
          deadline: deadline
        })
        
        result[:content].first[:text]
      rescue => e
        "Error updating task: #{e.message}"
      end
    end
  end
end