# frozen_string_literal: true

require_relative 'common'

module Things3Mcp
  module AppleScript
    module Generator
      module Tasks
        extend Common
        module_function

        LIST_NAMES = {
          'inbox' => 'Inbox', 'today' => 'Today', 'tomorrow' => 'Tomorrow', 'anytime' => 'Anytime',
          'upcoming' => 'Upcoming', 'someday' => 'Someday', 'logbook' => 'Logbook', 'trash' => 'Trash'
        }.freeze
        LISTS = LIST_NAMES.keys + ['all']
        STATUSES = %w[open completed canceled].freeze

        def list_script(list: nil, project: nil, area: nil, tag: nil, search: nil, status: nil, limit: nil)
          source, conditions = list_source(list, project, area, tag)
          conditions << "name of x contains #{Common.q(search)}" if search && !search.strip.empty?
          conditions << "status of x is #{status}" if status && STATUSES.include?(status)
          Common.tell(Common.collect_records('task', source, conditions: conditions, limit: limit))
        end

        def get_script(ref)
          Common.tell(
            "set t to my findTask(#{Common.q(ref)})",
            Common.return_record('task', 't')
          )
        end

        def add_script(name:, notes: nil, project: nil, area: nil, list: nil, tags: nil, due_date: nil, start_date: nil)
          props = ["name:#{Common.q(name)}"]
          props << "notes:#{Common.q(notes)}" if notes
          Common.tell(
            "set t to make new to do with properties {#{props.join(', ')}}",
            container_statements('t', project: project, area: area),
            list_statements('t', list),
            schedule_statements('t', start_date),
            due_date_statements('t', due_date),
            tags_statements('t', tags),
            Common.return_record('task', 't')
          )
        end

        def update_script(ref, name: nil, notes: nil, project: nil, area: nil, list: nil, tags: nil,
                          due_date: nil, start_date: nil, status: nil)
          Common.tell(
            "set t to my findTask(#{Common.q(ref)})",
            (name ? "set name of t to #{Common.q(name)}" : nil),
            (notes ? "set notes of t to #{Common.q(notes)}" : nil),
            container_statements('t', project: project, area: area),
            list_statements('t', list),
            schedule_statements('t', start_date),
            due_date_statements('t', due_date),
            tags_statements('t', tags),
            (status && STATUSES.include?(status) ? "set status of t to #{status}" : nil),
            Common.return_record('task', 't')
          )
        end

        def complete_script(ref)
          Common.tell(
            "set t to my findTask(#{Common.q(ref)})",
            'set status of t to completed',
            Common.return_record('task', 't')
          )
        end

        def delete_script(ref)
          Common.tell(
            "set t to my findTask(#{Common.q(ref)})",
            'set rec to my taskRecord(t)',
            'delete t',
            'return rec'
          )
        end

        def move_script(ref, destination:, destination_type:)
          statement = case destination_type
                      when 'project' then container_statements('t', project: destination)
                      when 'area' then container_statements('t', area: destination)
                      else list_statements('t', destination)
                      end
          Common.tell(
            "set t to my findTask(#{Common.q(ref)})",
            statement,
            Common.return_record('task', 't')
          )
        end

        # -- helpers -------------------------------------------------------------

        def list_name(list)
          LIST_NAMES[list.to_s.downcase] || list.to_s
        end

        def list_source(list, project, area, tag)
          conditions = []
          if list && list != 'all'
            source = "to dos of list #{Common.q(list_name(list))}"
            conditions << "my projectName(x) is #{Common.q(project)}" if project
            conditions << "my areaName(x) is #{Common.q(area)}" if area
            conditions << "#{Common.q(tag)} is in tag names of x" if tag
          elsif project
            source = "to dos of my findProject(#{Common.q(project)})"
            conditions << "#{Common.q(tag)} is in tag names of x" if tag
          elsif area
            source = "to dos of my findArea(#{Common.q(area)})"
            conditions << "#{Common.q(tag)} is in tag names of x" if tag
          elsif tag
            source = "to dos of my findTag(#{Common.q(tag)})"
          elsif list == 'all'
            source = 'to dos'
          else
            source = 'to dos of list "Today"'
          end
          [source, conditions]
        end

        # Things rejects `move toDo to project`; setting the property works.
        # Moving to the Inbox is the only way to clear a project or area.
        def container_statements(var, project: nil, area: nil)
          if project == 'none' || area == 'none'
            "move #{var} to list \"Inbox\""
          elsif project
            "set project of #{var} to my findProject(#{Common.q(project)})"
          elsif area
            "set area of #{var} to my findArea(#{Common.q(area)})"
          end
        end

        def list_statements(var, list)
          return nil unless list

          "move #{var} to list #{Common.q(list_name(list))}"
        end

        # A date hash schedules the item. :someday and :anytime move it to that
        # list, and :none (unschedule) also means Anytime.
        def schedule_statements(var, start_date)
          case start_date
          when nil then nil
          when :someday then "move #{var} to list \"Someday\""
          when :anytime, :none then "move #{var} to list \"Anytime\""
          else "schedule #{var} for #{Common.date_expr(start_date)}"
          end
        end

        def due_date_statements(var, due_date)
          return nil unless due_date
          if due_date.is_a?(Symbol)
            raise ArgumentError, 'Things AppleScript cannot clear a deadline. Set a new date instead.'
          end

          "set due date of #{var} to #{Common.date_expr(due_date)}"
        end

        def tags_statements(var, tags)
          return nil if tags.nil?

          "set tag names of #{var} to #{Common.q(Common.tag_names_expr(tags))}"
        end
      end
    end
  end
end
