require 'date'
require 'chronic'

module Things3Mcp
  class DateParser
    def initialize(debug: false)
      @debug = debug
      Chronic.time_class = Time
    end

    def parse_natural_date(date_input)
      return nil if date_input.nil? || date_input.strip.empty?
      return nil if date_input == "none"
      
      if date_input.match?(/^\d{4}-\d{2}-\d{2}$/)
        begin
          parsed = Date.parse(date_input)
          return {
            original_input: date_input,
            parsed_date: date_input,
            day_of_week: parsed.strftime("%A")
          }
        rescue Date::Error
          return nil
        end
      end
      
      normalized_input = normalize_date_input(date_input)
      parsed_time = Chronic.parse(normalized_input, context: :future)
      
      if parsed_time
        parsed_date = parsed_time.strftime("%Y-%m-%d")
        day_of_week = parsed_time.strftime("%A")
        
        {
          original_input: date_input,
          parsed_date: parsed_date,
          day_of_week: day_of_week
        }
      else
        log_debug("Failed to parse date: '#{date_input}' (normalized: '#{normalized_input}')")
        nil
      end
    end

    def parse_multiple_dates(date_inputs)
      return [] if date_inputs.nil? || date_inputs.empty?
      
      results = []
      date_inputs.each do |date_input|
        result = parse_natural_date(date_input)
        results << result if result
      end
      results
    end

    def date_in_past?(date_input)
      parsed = parse_natural_date(date_input)
      return false unless parsed
      
      parsed_date = Date.parse(parsed[:parsed_date])
      parsed_date < Date.today
    end

    def date_is_today?(date_input)
      parsed = parse_natural_date(date_input)
      return false unless parsed
      
      parsed_date = Date.parse(parsed[:parsed_date])
      parsed_date == Date.today
    end

    def get_relative_description(date_input)
      parsed = parse_natural_date(date_input)
      return nil unless parsed
      
      parsed_date = Date.parse(parsed[:parsed_date])
      today = Date.today
      
      days_diff = (parsed_date - today).to_i
      
      case days_diff
      when 0
        "today"
      when 1
        "tomorrow"
      when -1
        "yesterday"
      when 2..6
        "in #{days_diff} days"
      when -6..-2
        "#{days_diff.abs} days ago"
      when 7..13
        "next week"
      when -13..-7
        "last week"
      else
        if days_diff > 0
          "in #{(days_diff / 7.0).round} weeks"
        else
          "#{(days_diff.abs / 7.0).round} weeks ago"
        end
      end
    end

    def get_date_range(period)
      today = Date.today
      
      case period.to_s.downcase
      when "today"
        { start: today, end: today }
      when "tomorrow"
        tomorrow = today + 1
        { start: tomorrow, end: tomorrow }
      when "this_week"
        week_start = today - today.wday
        week_end = week_start + 6
        { start: week_start, end: week_end }
      when "next_week"
        next_week_start = today - today.wday + 7
        next_week_end = next_week_start + 6
        { start: next_week_start, end: next_week_end }
      when "last_week"
        last_week_start = today - today.wday - 7
        last_week_end = last_week_start + 6
        { start: last_week_start, end: last_week_end }
      when "this_month"
        month_start = Date.new(today.year, today.month, 1)
        month_end = Date.new(today.year, today.month, -1)
        { start: month_start, end: month_end }
      when "next_month"
        next_month = today.next_month
        month_start = Date.new(next_month.year, next_month.month, 1)
        month_end = Date.new(next_month.year, next_month.month, -1)
        { start: month_start, end: month_end }
      when "last_month"
        last_month = today.prev_month
        month_start = Date.new(last_month.year, last_month.month, 1)
        month_end = Date.new(last_month.year, last_month.month, -1)
        { start: month_start, end: month_end }
      else
        nil
      end
    end

    def format_for_applescript(date_input)
      parsed = parse_natural_date(date_input)
      return nil unless parsed
      parsed[:parsed_date]
    end

    def overdue?(date_input)
      return false unless date_input
      
      parsed = parse_natural_date(date_input)
      return false unless parsed
      
      parsed_date = Date.parse(parsed[:parsed_date])
      parsed_date < Date.today
    end

    def due_within_days(date_input, days)
      return false unless date_input
      
      parsed = parse_natural_date(date_input)
      return false unless parsed
      
      parsed_date = Date.parse(parsed[:parsed_date])
      target_date = Date.today + days
      
      parsed_date <= target_date && parsed_date >= Date.today
    end

    private

    def normalize_date_input(input)
      normalized = input.downcase.strip
      
      normalized = normalized.gsub(/^in (\d+) days?$/, '\1 days from now')
      normalized = normalized.gsub(/^in (\d+) weeks?$/, '\1 weeks from now')
      normalized = normalized.gsub(/^in (\d+) months?$/, '\1 months from now')
      
      normalized = normalized.gsub(/(\d+) days? from now/, '\1 days from now')
      normalized = normalized.gsub(/(\d+) weeks? from now/, '\1 weeks from now')
      normalized = normalized.gsub(/(\d+) months? from now/, '\1 months from now')
      
      normalized = normalized.gsub(/^day after tomorrow$/, '2 days from now')
      normalized = normalized.gsub(/^the day after tomorrow$/, '2 days from now')
      
      normalized = normalized.gsub(/^end of (?:this )?week$/, 'this sunday')
      normalized = normalized.gsub(/^end of (?:this )?month$/, 'last day of this month')
      normalized = normalized.gsub(/^end of (?:the )?year$/, 'december 31')
      
      normalized = normalized.gsub(/^beginning of (?:next )?week$/, 'next monday')
      normalized = normalized.gsub(/^start of (?:next )?week$/, 'next monday')
      normalized = normalized.gsub(/^beginning of (?:next )?month$/, 'first day of next month')
      
      normalized = normalized.gsub(/^christmas$/, 'december 25')
      normalized = normalized.gsub(/^new years?$/, 'january 1')
      normalized = normalized.gsub(/^new years? day$/, 'january 1')
      
      normalized = normalized.gsub(/^next business day$/, 'next weekday')
      normalized = normalized.gsub(/^next weekday$/, 'next monday')
      
      normalized = normalized.gsub(/^eod$/, 'end of day')
      normalized = normalized.gsub(/^end of day$/, 'today 5pm')
      normalized = normalized.gsub(/^first thing$/, 'tomorrow 9am')
      
      normalized
    end

    def log_debug(message)
      puts "[DateParser] #{message}" if @debug
    end
  end
end