# frozen_string_literal: true

module Things3Mcp
  # Parses the delimited text that the AppleScript handlers return.
  # Fields are separated by ASCII 31, records by ASCII 30.
  module RecordParser
    FIELD_SEP = "\u001F"
    RECORD_SEP = "\u001E"
    LIST_FIELDS = %i[tags].freeze

    module_function

    def parse_many(text, fields)
      text = text.to_s.dup.force_encoding('UTF-8').chomp
      return [] if text.empty?

      text.split(RECORD_SEP).map { |record| parse_one(record, fields) }
    end

    def parse_one(text, fields)
      values = text.to_s.dup.force_encoding('UTF-8').chomp.split(FIELD_SEP, -1)
      fields.each_with_index.to_h do |field, i|
        [field, convert(field, values[i])]
      end
    end

    def convert(field, value)
      value = value.to_s
      if LIST_FIELDS.include?(field)
        value.split(',').map(&:strip).reject(&:empty?)
      elsif field == :task_count
        value.to_i
      elsif field == :notes
        value.gsub('\\n', "\n")
      elsif value.empty?
        nil
      else
        value
      end
    end
  end
end
