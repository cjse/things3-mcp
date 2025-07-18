require 'fast_mcp'

module Things3Mcp
  module Tools
    class MoveTaskTool < FastMcp::Tool
      tool_name 'move_task'
      description "Move a task to a different project or area in Things 3"
      
      arguments do
        required(:task_id).filled(:string).description("Task ID or title to identify the task")
        required(:destination).filled(:string).description("Destination project or area name")
        required(:destination_type).filled(:string).description("Whether destination is a project or area (project, area)")
      end
      
      def call(task_id:, destination:, destination_type:)
        executor = AppleScript::Executor.new(debug: false)
        date_parser = DateParser.new(debug: false)
        client = Client.new(executor, date_parser, debug: false)
        
        result = client.move_task({
          task_id: task_id,
          destination: destination,
          destination_type: destination_type
        })
        
        result[:content].first[:text]
      rescue => e
        "Error moving task: #{e.message}"
      end
    end
  end
end