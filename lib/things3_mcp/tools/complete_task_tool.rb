# frozen_string_literal: true

require_relative 'base_tool'

module Things3Mcp
  module Tools
    class CompleteTaskTool < BaseTool
      tool_name 'complete_task'
      title 'Complete task'
      description 'Mark a task in Things 3 as completed.'
      input_schema(
        properties: { task_id: { type: 'string', description: 'Task id or exact name' } },
        required: ['task_id']
      )
      output_schema(TASK_SCHEMA)
      annotations(read_only_hint: false, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.call(task_id:, server_context: nil)
        guarded do
          task = client.complete_task(task_id)
          record_response(task, "Completed: #{summarize_task(task)}")
        end
      end
    end
  end
end
