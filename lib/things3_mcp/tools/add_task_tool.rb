# frozen_string_literal: true

require_relative 'base_tool'

module Things3Mcp
  module Tools
    class AddTaskTool < BaseTool
      tool_name 'add_task'
      title 'Add task'
      description 'Create a task in Things 3. Goes to the Inbox unless a project, area, or list is given.'
      input_schema(
        properties: {
          title: { type: 'string', description: 'Task title' },
          notes: { type: 'string' },
          project: { type: 'string', description: 'Project name or id to put the task in' },
          area: { type: 'string', description: 'Area name or id to put the task in' },
          list: { type: 'string', enum: %w[inbox today anytime someday], description: 'Built-in list to put the task in' },
          tags: { type: 'array', items: { type: 'string' } },
          due_date: { type: 'string', description: "Deadline. #{DATE_DESC}" },
          start_date: { type: 'string', description: "When to start (the \"when\" date). #{DATE_DESC}" }
        },
        required: ['title']
      )
      output_schema(TASK_SCHEMA)
      annotations(read_only_hint: false, destructive_hint: false, idempotent_hint: false, open_world_hint: false)

      def self.call(title:, notes: nil, project: nil, area: nil, list: nil, tags: nil, due_date: nil, start_date: nil, server_context: nil)
        guarded do
          task = client.add_task(title: title, notes: notes, project: project, area: area, list: list, tags: tags,
                                 due_date: due_date, start_date: start_date)
          record_response(task, "Created: #{summarize_task(task)}")
        end
      end
    end
  end
end
