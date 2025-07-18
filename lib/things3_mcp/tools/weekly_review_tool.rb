require 'fast_mcp'

module Things3Mcp
  module Tools
    class WeeklyReviewTool < FastMcp::Tool
      tool_name 'weekly_review'
      description "Generate comprehensive weekly productivity review with completed tasks, upcoming deadlines, and insights"
      
      arguments do
        optional(:week_offset).filled(:integer).description("Number of weeks from current (0 = this week, -1 = last week)")
        optional(:include_completed).filled(:bool).description("Include completed tasks in review")
        optional(:include_upcoming).filled(:bool).description("Include upcoming tasks in review")
      end
      
      def call(week_offset: 0, include_completed: true, include_upcoming: true)
        executor = AppleScript::Executor.new(debug: false)
        date_parser = DateParser.new(debug: false)
        report_gen = ReportGenerator.new(executor, date_parser, debug: false)
        
        result = report_gen.weekly_review({
          week_offset: week_offset,
          include_completed: include_completed,
          include_upcoming: include_upcoming
        })
        
        result[:content].first[:text]
      rescue => e
        "Error generating weekly review: #{e.message}"
      end
    end
  end
end