require 'fast_mcp'

module Things3Mcp
  module Tools
    class ProductivityStatsTool < FastMcp::Tool
      tool_name 'productivity_stats'
      description "Analyze productivity patterns and task completion statistics"
      
      arguments do
        optional(:period).filled(:string).description("Time period for analysis (week, month, quarter, year)")
        optional(:group_by).filled(:string).description("How to group the statistics (day, week, month, project, area, tag)")
      end
      
      def call(period: "week", group_by: "day")
        executor = AppleScript::Executor.new(debug: false)
        date_parser = DateParser.new(debug: false)
        report_gen = ReportGenerator.new(executor, date_parser, debug: false)
        
        result = report_gen.productivity_stats({
          period: period,
          group_by: group_by
        })
        
        result[:content].first[:text]
      rescue => e
        "Error generating productivity stats: #{e.message}"
      end
    end
  end
end