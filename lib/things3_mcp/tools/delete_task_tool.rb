# frozen_string_literal: true

require_relative 'base_tool'

module Things3Mcp
  module Tools
    class DeleteTaskTool < BaseTool
      tool_name 'delete_task'
      title 'Delete task'
      description 'Move a task in Things 3 to the Trash.'
      input_schema(
        properties: { task_id: { type: 'string', description: 'Task id or exact name' } },
        required: ['task_id']
      )
      output_schema(TASK_SCHEMA)
      annotations(read_only_hint: false, destructive_hint: true, idempotent_hint: false, open_world_hint: false)

      def self.call(task_id:, server_context: nil)
        guarded do
          task = client.delete_task(task_id)
          record_response(task, "Moved to Trash: #{summarize_task(task)}")
        end
      end
    end
  end
end
