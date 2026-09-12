# frozen_string_literal: true

require_relative 'base_tool'

module Things3Mcp
  module Tools
    class GetTaskTool < BaseTool
      tool_name 'get_task'
      title 'Get task'
      description 'Show one task in Things 3 with all its fields. Looks up by id first, then by exact name.'
      input_schema(
        properties: { task_id: { type: 'string', description: 'Task id or exact name' } },
        required: ['task_id']
      )
      output_schema(TASK_SCHEMA)
      annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.call(task_id:, server_context: nil)
        guarded do
          task = client.get_task(task_id)
          record_response(task, summarize_task(task))
        end
      end
    end
  end
end
