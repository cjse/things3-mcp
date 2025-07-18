require 'fast_mcp'

module Things3Mcp
  module Tools
    class BulkCreateTool < FastMcp::Tool
      tool_name 'bulk_create'
      description "Create multiple tasks at once from various input formats"
      
      arguments do
        required(:tasks).array(:hash).description("Array of task objects to create")
        optional(:format).filled(:string).description("Input format (json, csv, text)")
      end
      
      def call(tasks:, format: "json")
        executor = AppleScript::Executor.new(debug: false)
        date_parser = DateParser.new(debug: false)
        client = Client.new(executor, date_parser, debug: false)
        bulk_ops = BulkOperations.new(
          executor,
          client.method(:add_task),
          client.method(:update_task),
          client.method(:move_task),
          client.method(:complete_task),
          client.method(:escape_quotes),
          debug: false
        )
        
        result = bulk_ops.bulk_create({
          tasks: tasks,
          format: format
        })
        
        result[:content].first[:text]
      rescue => e
        "Error creating tasks in bulk: #{e.message}"
      end
    end
  end
end