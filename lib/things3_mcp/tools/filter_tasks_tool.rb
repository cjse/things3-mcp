require 'fast_mcp'

module Things3Mcp
  module Tools
    class FilterTasksTool < FastMcp::Tool
      tool_name 'filter_tasks'
      description "Advanced task filtering with multiple criteria including status, projects, areas, tags, dates, and text search"
      
      arguments do
        optional(:status_filter).array(:string).description("Filter by task status (open, completed, canceled)")
        optional(:project_names).array(:string).description("Filter by project names")
        optional(:area_names).array(:string).description("Filter by area names")
        optional(:tag_filter).array(:string).description("Filter by tags")
        optional(:has_due_date).filled(:bool).description("Filter tasks with/without due dates")
        optional(:due_before).filled(:string).description("Filter tasks due before this date")
        optional(:due_after).filled(:string).description("Filter tasks due after this date")
        optional(:text_search).filled(:string).description("Search in task titles and notes")
      end
      
      def call(status_filter: nil, project_names: nil, area_names: nil, tag_filter: nil, 
               has_due_date: nil, due_before: nil, due_after: nil, text_search: nil)
        executor = AppleScript::Executor.new(debug: false)
        date_parser = DateParser.new(debug: false)
        task_filter = TaskFilter.new(executor, date_parser, debug: false)
        
        result = task_filter.filter_tasks({
          status_filter: status_filter,
          project_names: project_names,
          area_names: area_names,
          tag_filter: tag_filter,
          has_due_date: has_due_date,
          due_before: due_before,
          due_after: due_after,
          text_search: text_search
        })
        
        result[:content].first[:text]
      rescue => e
        "Error filtering tasks: #{e.message}"
      end
    end
  end
end