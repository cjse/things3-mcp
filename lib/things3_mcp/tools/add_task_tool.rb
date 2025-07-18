require 'fast_mcp'

module Things3Mcp
  module Tools
    class AddTaskTool < FastMcp::Tool
      tool_name 'add_task'
      description "Add a new task to Things 3 with natural language date parsing and smart organization"
      
      arguments do
        required(:title).filled(:string).description("Task title")
        optional(:notes).filled(:string).description("Task notes")
        optional(:project).filled(:string).description("Project name")
        optional(:area).filled(:string).description("Area name")
        optional(:tags).array(:string).description("Tags")
        optional(:due_date).filled(:string).description("Due date (natural language)")
        optional(:start_date).filled(:string).description("Start date (natural language)")
        optional(:deadline).filled(:string).description("Deadline (natural language)")
      end
      
      def call(title:, notes: nil, project: nil, area: nil, tags: nil, due_date: nil, start_date: nil, deadline: nil)
        executor = AppleScript::Executor.new(debug: false)
        date_parser = DateParser.new(debug: false)
        client = Client.new(executor, date_parser, debug: false)
        
        result = client.add_task({
          title: title,
          notes: notes,
          project: project,
          area: area,
          tags: tags || [],
          due_date: due_date,
          start_date: start_date,
          deadline: deadline
        })
        
        result[:content].first[:text]
      rescue => e
        "Error adding task: #{e.message}"
      end
    end
  end
end