require 'fast_mcp'

module Things3Mcp
  module Tools
    class DeleteTaskTool < FastMcp::Tool
      tool_name 'delete_task'
      description "Delete a task from Things 3"
      
      arguments do
        required(:task_id).filled(:string).description("Task ID or title to identify the task")
      end
      
      def call(task_id:)
        executor = AppleScript::Executor.new(debug: false)
        date_parser = DateParser.new(debug: false)
        client = Client.new(executor, date_parser, debug: false)
        
        result = client.delete_task({
          task_id: task_id
        })
        
        result[:content].first[:text]
      rescue => e
        "Error deleting task: #{e.message}"
      end
    end
  end
end