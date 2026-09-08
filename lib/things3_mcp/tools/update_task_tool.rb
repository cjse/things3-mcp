# frozen_string_literal: true

require_relative 'base_tool'

module Things3Mcp
  module Tools
    class UpdateTaskTool < BaseTool
      tool_name 'update_task'
      title 'Update task'
      description 'Change fields of an existing task in Things 3. Only the given fields change. ' \
                  'Use project or area "none" to move the task back to the Inbox.'
      input_schema(
        properties: {
          task_id: { type: 'string', description: 'Task id or exact name' },
          title: { type: 'string', description: 'New title' },
          notes: { type: 'string', description: 'New notes (replaces existing notes)' },
          project: { type: 'string', description: 'Project name or id, or "none"' },
          area: { type: 'string', description: 'Area name or id, or "none"' },
          list: { type: 'string', enum: %w[inbox today anytime someday] },
          tags: { type: 'array', items: { type: 'string' }, description: 'Replaces all tags' },
          due_date: { type: 'string', description: "Deadline. #{DATE_DESC}" },
          start_date: { type: 'string', description: "When to start. #{DATE_DESC}" },
          status: { type: 'string', enum: %w[open completed canceled] }
        },
        required: ['task_id']
      )
      output_schema(TASK_SCHEMA)
      annotations(read_only_hint: false, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.call(task_id:, title: nil, notes: nil, project: nil, area: nil, list: nil, tags: nil,
                    due_date: nil, start_date: nil, status: nil, server_context: nil)
        guarded do
          task = client.update_task(task_id, title: title, notes: notes, project: project, area: area, list: list,
                                    tags: tags, due_date: due_date, start_date: start_date, status: status)
          record_response(task, "Updated: #{summarize_task(task)}")
        end
      end
    end
  end
end
