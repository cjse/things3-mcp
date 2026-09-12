# frozen_string_literal: true

require_relative 'base_tool'

module Things3Mcp
  module Tools
    class GetTasksTool < BaseTool
      LISTS = AppleScript::Generator::Tasks::LISTS

      tool_name 'get_tasks'
      title 'Get tasks'
      description 'List tasks from Things 3. Filter by built-in list, project, area, tag, name search, or status. ' \
                  'Defaults to the Today list when no filter is given. "logbook" holds completed tasks.'
      input_schema(
        properties: {
          list: { type: 'string', enum: LISTS, description: 'Built-in list. "all" means every active task.' },
          project: { type: 'string', description: 'Project name or id' },
          area: { type: 'string', description: 'Area name or id' },
          tag: { type: 'string', description: 'Tag name' },
          search: { type: 'string', description: 'Only tasks whose name contains this text' },
          status: { type: 'string', enum: %w[open completed canceled] },
          limit: { type: 'integer', minimum: 1, description: 'Maximum number of tasks to return' }
        }
      )
      output_schema(list_schema(:tasks, TASK_SCHEMA))
      annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.call(list: nil, project: nil, area: nil, tag: nil, search: nil, status: nil, limit: nil, server_context: nil)
        guarded do
          tasks = client.list_tasks(list: list, project: project, area: area, tag: tag, search: search, status: status, limit: limit)
          list_response(:tasks, tasks, bullet_list(tasks.map { |t| summarize_task(t) }, 'No tasks found'))
        end
      end
    end
  end
end
