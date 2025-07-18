# frozen_string_literal: true

require 'fast_mcp'

module Things3Mcp
  module Tools
    class GetTasksTool < FastMcp::Tool
      tool_name 'get_tasks'
      description "Retrieve tasks from Things 3 with various filtering options"
      
      arguments do
        optional(:list).filled(:string).description("Which list to retrieve from (inbox, today, anytime, upcoming, someday, completed, canceled, all)")
        optional(:project).filled(:string).description("Filter by project name")
        optional(:area).filled(:string).description("Filter by area name")
        optional(:tag).filled(:string).description("Filter by tag")
        optional(:limit).filled(:integer).description("Maximum number of tasks to return")
      end
      
      def call(list: nil, project: nil, area: nil, tag: nil, limit: nil)
        executor = AppleScript::Executor.new(debug: false)
        date_parser = DateParser.new(debug: false)
        client = Client.new(executor, date_parser, debug: false)
        
        result = client.get_tasks({
          list: list,
          project: project,
          area: area,
          tag: tag,
          limit: limit
        })
        
        result[:content].first[:text]
      rescue => e
        "Error getting tasks: #{e.message}"
      end
    end
  end
end