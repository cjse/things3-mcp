require 'fast_mcp'

module Things3Mcp
  module Tools
    class CompleteTaskTool < FastMcp::Tool
      tool_name 'complete_task'
      description "Mark a task as completed in Things 3"
      
      arguments do
        required(:task_id).filled(:string).description("Task ID or title to identify the task")
      end
      
      def call(task_id:)
        executor = AppleScript::Executor.new(debug: false)
        date_parser = DateParser.new(debug: false)
        client = Client.new(executor, date_parser, debug: false)
        
        result = client.complete_task({
          task_id: task_id
        })
        
        result[:content].first[:text]
      rescue => e
        "Error completing task: #{e.message}"
      end
    end
  end
end