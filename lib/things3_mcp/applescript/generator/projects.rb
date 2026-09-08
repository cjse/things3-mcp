# frozen_string_literal: true

require_relative 'common'
require_relative 'tasks'

module Things3Mcp
  module AppleScript
    module Generator
      module Projects
        extend Common
        module_function

        STATUSES = %w[open completed canceled].freeze

        def list_script(area: nil, status: nil, tag: nil, search: nil, limit: nil)
          conditions = []
          conditions << "my areaName(x) is #{Common.q(area)}" if area
          conditions << "status of x is #{status}" if status && STATUSES.include?(status)
          conditions << "tag names of x contains #{Common.q(tag)}" if tag
          conditions << "name of x contains #{Common.q(search)}" if search && !search.strip.empty?
          Common.tell(Common.collect_records('project', 'projects', conditions: conditions, limit: limit))
        end

        def get_script(ref)
          Common.tell(
            "set p to my findProject(#{Common.q(ref)})",
            Common.return_record('project', 'p')
          )
        end

        def tasks_script(ref, status: 'open')
          conditions = []
          conditions << "status of x is #{status}" if status && STATUSES.include?(status)
          Common.tell(
            "set p to my findProject(#{Common.q(ref)})",
            Common.collect_records('task', 'to dos of p', conditions: conditions)
          )
        end

        def add_script(name:, notes: nil, area: nil, tags: nil, due_date: nil, start_date: nil)
          props = ["name:#{Common.q(name)}"]
          props << "notes:#{Common.q(notes)}" if notes
          Common.tell(
            "set p to make new project with properties {#{props.join(', ')}}",
            (area ? "set area of p to my findArea(#{Common.q(area)})" : nil),
            Tasks.schedule_statements('p', start_date),
            Tasks.due_date_statements('p', due_date),
            Tasks.tags_statements('p', tags),
            Common.return_record('project', 'p')
          )
        end

        def update_script(ref, name: nil, notes: nil, area: nil, tags: nil, due_date: nil, start_date: nil, status: nil)
          if area == 'none'
            raise ArgumentError, 'Things AppleScript cannot remove a project from its area. Move it to another area instead.'
          end
          area_statement = area ? "set area of p to my findArea(#{Common.q(area)})" : nil
          Common.tell(
            "set p to my findProject(#{Common.q(ref)})",
            (name ? "set name of p to #{Common.q(name)}" : nil),
            (notes ? "set notes of p to #{Common.q(notes)}" : nil),
            area_statement,
            Tasks.schedule_statements('p', start_date),
            Tasks.due_date_statements('p', due_date),
            Tasks.tags_statements('p', tags),
            (status && STATUSES.include?(status) ? "set status of p to #{status}" : nil),
            Common.return_record('project', 'p')
          )
        end

        def delete_script(ref)
          Common.tell(
            "set p to my findProject(#{Common.q(ref)})",
            'set rec to my projectRecord(p)',
            'delete p',
            'return rec'
          )
        end
      end
    end
  end
end
