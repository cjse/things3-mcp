# frozen_string_literal: true

require 'mcp'
require 'json'

module Things3Mcp
  module Tools
    # Shared plumbing for every tool: access to the process-wide client, JSON
    # schemas for the record types, and response helpers.
    class BaseTool < MCP::Tool
      DATE_DESC = 'Natural language ("tomorrow", "next friday", "in 2 weeks") or YYYY-MM-DD. Use "none" to clear.'

      TASK_SCHEMA = {
        type: 'object',
        properties: {
          id: { type: 'string' },
          name: { type: 'string' },
          status: { type: 'string', enum: %w[open completed canceled] },
          notes: { type: %w[string null] },
          project: { type: %w[string null] },
          area: { type: %w[string null] },
          tags: { type: 'array', items: { type: 'string' } },
          due_date: { type: %w[string null], description: 'YYYY-MM-DD' },
          start_date: { type: %w[string null], description: 'YYYY-MM-DD (the "when" date)' },
          creation_date: { type: %w[string null] },
          completion_date: { type: %w[string null] }
        }
      }.freeze

      PROJECT_SCHEMA = {
        type: 'object',
        properties: {
          id: { type: 'string' },
          name: { type: 'string' },
          status: { type: 'string', enum: %w[open completed canceled] },
          notes: { type: %w[string null] },
          area: { type: %w[string null] },
          tags: { type: 'array', items: { type: 'string' } },
          due_date: { type: %w[string null] },
          start_date: { type: %w[string null] },
          creation_date: { type: %w[string null] },
          task_count: { type: 'integer' }
        }
      }.freeze

      AREA_SCHEMA = {
        type: 'object',
        properties: {
          id: { type: 'string' },
          name: { type: 'string' },
          tags: { type: 'array', items: { type: 'string' } }
        }
      }.freeze

      TAG_SCHEMA = {
        type: 'object',
        properties: {
          id: { type: 'string' },
          name: { type: 'string' },
          parent: { type: %w[string null] }
        }
      }.freeze

      class << self
        def client
          Things3Mcp.client
        end

        # Wraps a tool body so AppleScript and date errors reach the model as
        # error responses instead of opaque internal errors.
        def guarded
          yield
        rescue AppleScript::Executor::AppleScriptError, DateParser::UnparseableDate, ArgumentError => e
          MCP::Tool::Response.new([{ type: 'text', text: e.message }], error: true)
        end

        def record_response(record, text)
          MCP::Tool::Response.new([{ type: 'text', text: text }], structured_content: record)
        end

        def list_response(key, records, text)
          MCP::Tool::Response.new([{ type: 'text', text: text }], structured_content: { key => records, count: records.size })
        end

        def list_schema(key, item_schema)
          { properties: { key => { type: 'array', items: item_schema }, count: { type: 'integer' } }, required: [key.to_s, 'count'] }
        end

        def summarize_task(t)
          parts = ["#{t[:name]} (id: #{t[:id]})"]
          parts << "[#{t[:status]}]" unless t[:status] == 'open'
          parts << "project: #{t[:project]}" if t[:project]
          parts << "area: #{t[:area]}" if t[:area]
          parts << "when: #{t[:start_date]}" if t[:start_date]
          parts << "due: #{t[:due_date]}" if t[:due_date]
          parts << "tags: #{t[:tags].join(', ')}" if t[:tags]&.any?
          line = parts.join(' | ')
          line += "\n  notes: #{t[:notes].gsub("\n", "\n  ")}" if t[:notes] && !t[:notes].empty?
          line
        end

        def summarize_project(p)
          parts = ["#{p[:name]} (id: #{p[:id]})"]
          parts << "[#{p[:status]}]" unless p[:status] == 'open'
          parts << "area: #{p[:area]}" if p[:area]
          parts << "when: #{p[:start_date]}" if p[:start_date]
          parts << "due: #{p[:due_date]}" if p[:due_date]
          parts << "tags: #{p[:tags].join(', ')}" if p[:tags]&.any?
          parts << "#{p[:task_count]} open to dos" if p.key?(:task_count)
          parts.join(' | ')
        end

        def bullet_list(lines, empty_text)
          lines.empty? ? empty_text : lines.map { |l| "- #{l}" }.join("\n")
        end
      end
    end
  end
end
