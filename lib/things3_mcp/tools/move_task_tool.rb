# frozen_string_literal: true

require_relative 'base_tool'

module Things3Mcp
  module Tools
    class MoveTaskTool < BaseTool
      tool_name 'move_task'
      title 'Move task'
      description 'Move a task in Things 3 to a project, an area, or a built-in list (inbox, today, anytime, someday).'
      input_schema(
        properties: {
          task_id: { type: 'string', description: 'Task id or exact name' },
          destination: { type: 'string', description: 'Project or area name or id, or a list name' },
          destination_type: { type: 'string', enum: %w[project area list] }
        },
        required: %w[task_id destination destination_type]
      )
      output_schema(TASK_SCHEMA)
      annotations(read_only_hint: false, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.call(task_id:, destination:, destination_type:, server_context: nil)
        guarded do
          task = client.move_task(task_id, destination: destination, destination_type: destination_type)
          record_response(task, "Moved: #{summarize_task(task)}")
        end
      end
    end
  end
end
