# frozen_string_literal: true

module Things3Mcp
  module AppleScript
    class Generator
      APP_NAME = 'Things3'

      class << self
        def add_task_script(name:, notes: nil, project: nil, area: nil, due_date: nil, start_date: nil, tags: [])
          tell(APP_NAME) do |app|
            app.try "set theToDo to make new to do with " + properties_script(name:, notes:)
            app.try "set result_parts to {\"Task created: \" & name of theToDo}"
            app.try set_project_or_area_script(project, area)
            app.try set_start_date_script(start_date)
            app.try set_due_date_script(due_date)
            app.try set_tags_script(tags) unless tags.empty?
            app.try "return result_parts as string"
            app.on_error "return \"❌ Task could not be added: #{escape_quotes(name)}\""
          end
        end

        def complete_task_script(task_id:)
          tell(APP_NAME) do |app|
            app.try "set theToDo to " + task_with_name_script(task_id, status: "open")
            app.try "set status of theToDo to completed"
            app.try 'return "✅ Completed: " & name of theToDo'
            app.on_error "return \"❌ Task not found or already completed: #{escape_quotes(task_id)}\""
          end
        end

        def delete_task_script(task_id:)
          tell(APP_NAME) do |app|
            app.try "set theToDo to " + task_with_name_script(task_id)
            app.try "set taskName to name of theToDo"
            app.try "delete theToDo"
            app.try 'return "🗑️ Deleted task: " & taskName'
            app.on_error "return \"❌ Task not found: #{escape_quotes(task_id)}\""
          end
        end

        def move_task_script(task_id:, destination:, destination_type:)
          tell(APP_NAME) do |app|
            app.try "set theToDo to " + task_with_name_script(task_id, status: "open")
            app.try "set targetDestination to first #{destination_type} whose name is \"#{escape_quotes(destination)}\""
            app.try "move theToDo to targetDestination"
            app.try %Q(return "📁 Moved '" & name of theToDo & "' to #{destination_type}: #{escape_quotes(destination)}")

            app.on_error %Q(if errorMsg contains "Can't get #{destination_type}" then)
            app.on_error %Q(  return "❌ #{destination_type} not found: #{escape_quotes(destination)}")
            app.on_error %Q(else)
            app.on_error %Q(  return "❌ Task not found: #{escape_quotes(task_id)}")
            app.on_error %Q(end if)
          end
        end

        def list_tasks_script(list_type:, project_filter: nil, area_filter: nil, tag_filter: nil, limit: nil)
          tell(APP_NAME) do |app|
            app.do 'set taskList to {}'
            app.do 'set taskCount to 0'
            app.do 'set theTasks to ' + tasks_of_list_type_script(list_type)
            app.do project_or_area_filter_script(project_filter, area_filter)
            app.do tag_filter_script(tag_filter)

            app.do <<~APPLESCRIPT
              repeat with aToDo in theTasks
                #{limit_check_script(limit)}
                #{add_task_info_script}
              end repeat
              if length of taskList is 0 then
                return "No tasks found in #{list_type} list"
              else
                return taskList as string
              end if
            APPLESCRIPT
          end
        end

        def update_task_script(task_id:, title: nil, notes: nil, project: nil, area: nil,
                                  due_date: nil, start_date: nil, tags: nil)
          tell(APP_NAME) do |app|
            app.try "set theToDo to " + task_with_name_script(task_id, status: "open")
            app.try "set result_parts to {}"
            app.try set_name_script(title)
            app.try set_notes_script(notes)
            app.try set_project_script(project)
            app.try set_area_script(area)
            app.try set_start_date_script(start_date)
            app.try set_due_date_script(due_date)
            app.try set_tags_script(tags)
            app.try <<~APPLESCRIPT
              if length of result_parts is 0 then
                return "❓ No changes specified for task '#{escape_quotes(task_id)}'"
              else
                return "✏️ Updated '" & name of theToDo & "'"
              end if
            APPLESCRIPT

            app.on_error %Q(return "❌ Task not found: #{escape_quotes(task_id)}")
          end
        end

        private

        def tell(app_name)
          builder = Builder.new(app_name)
          yield(builder) if block_given?
          builder.to_script
        end

        def escape_quotes(str)
          return '' if str.nil?
          str.to_s.force_encoding('UTF-8').gsub('"', '\\"')
        end

        def set_project_or_area_script(project, area)
          project ? set_project_script(project) : set_area_script(area)
        end

        def set_name_script(name)
          if name
            <<~SET_NAME_SCRIPT
              set name of theToDo to "#{escape_quotes(name)}"
              set end of result_parts to "Updated name"
            SET_NAME_SCRIPT
          end
        end

        def set_notes_script(notes)
          if notes
            <<~SET_NOTES_SCRIPT
              set notes of theToDo to "#{escape_quotes(notes)}"
              set end of result_parts to "notes"
            SET_NOTES_SCRIPT
          end
        end

        def set_project_script(project)
          if project == "none"
            <<~REMOVE_PROJECT_SCRIPT
              try
                move theToDo to list "Inbox"
                set end of result_parts to "removed from project"
              end try
            REMOVE_PROJECT_SCRIPT
          elsif project
            <<~SET_PROJECT_SCRIPT
              try
                set targetDestination to first project whose name is "#{escape_quotes(project)}"
                move theToDo to targetDestination
                set end of result_parts to "Moved to project '#{escape_quotes(project)}'"
              on error
                set end of result_parts to "Project '#{escape_quotes(project)}' not found"
              end try
            SET_PROJECT_SCRIPT
          end
        end

        def set_area_script(area)
          if area == "none"
            <<~REMOVE_AREA_SCRIPT
              try
                move theToDo to list "Inbox"
                set end of result_parts to "removed from area"
              end try
            REMOVE_AREA_SCRIPT
          elsif area
            <<~SET_AREA_SCRIPT
              try
                set targetDestination to first area whose name is "#{escape_quotes(area)}"
                move theToDo to targetDestination
                set end of result_parts to "Moved to area '#{escape_quotes(area)}'"
              on error
                set end of result_parts to "Area '#{escape_quotes(area)}' not found"
              end try
            SET_AREA_SCRIPT
          end
        end

        def set_start_date_script(start_date)
          if start_date
            <<~SET_START_DATE_SCRIPT
              try
                schedule theToDo for date "#{start_date[:parsed_date]}"
                set end of result_parts to "Start: #{start_date[:parsed_date]}"
              on error
                set end of result_parts to "Invalid start date format"
              end try
            SET_START_DATE_SCRIPT
          end
        end

        def set_due_date_script(due_date)
          if due_date
            <<~SET_DUE_DATE_SCRIPT
              try
                set due date of theToDo to date "#{due_date[:parsed_date]}"
                set end of result_parts to "Due: #{due_date[:parsed_date]}"
              on error
                set end of result_parts to "Invalid due date format"
              end try
            SET_DUE_DATE_SCRIPT
          end
        end

        def set_tags_script(tags)
          if tags
            tag_string = tags.join(", ")
            <<~SET_TAGS_SCRIPT
              set tag names of theToDo to "#{escape_quotes(tag_string)}"
              set end of result_parts to "Updated tags"
            SET_TAGS_SCRIPT
          end
        end

        def properties_script(name:, notes: nil)
          script = "properties {name:\"#{escape_quotes(name)}\""
          script << ", notes:\"#{escape_quotes(notes)}\"" if notes
          script << "}"
        end

        def task_with_name_script(name, status: nil)
          script = "first to do whose name is \"#{escape_quotes(name)}\""
          script << " and status is #{status}" if status
          script
        end

        def project_or_area_filter_script(project_filter, area_filter)
          if filter = project_filter || area_filter
            filter_type = project_filter ? "project" : "area"
            filter_tasks_script(filter, filter_type)
          end
        end

        def tag_filter_script(tag_filter)
          filter_tasks_script(tag_filter, "tags") if tag_filter
        end

        def filter_tasks_script(filter, filter_type)
          filter_statement = case filter_type
            when "tags"    then %Q(tag names of aToDo contains "#{escape_quotes(filter)}")
            when "project" then %Q(name of project of aToDo is "#{escape_quotes(filter)}")
            when "area"    then %Q(name of area of aToDo is "#{escape_quotes(filter)}")
          end

          <<~FILTER_SCRIPT
            set filteredTasks to {}
            repeat with aToDo in theTasks
              try
                if #{filter_statement} then
                  set end of filteredTasks to aToDo
                end if
              end try
            end repeat
            set theTasks to filteredTasks
          FILTER_SCRIPT
        end

        def tasks_of_list_type_script(list_type)
          list_names = {"inbox" => "Inbox", "today" => "Today", "upcoming" => "Upcoming", "anytime" => "Anytime", "someday" => "Someday"}

          case list_type
            when 'completed' then 'completed to dos'
            when 'canceled' then 'canceled to dos'
            when 'all' then 'to dos'
          else
            %Q[to dos of list "#{list_names[list_type]}"]
          end
        end

        def limit_check_script(limit)
          if limit
            <<~LIMIT_CHECK_SCRIPT
              if taskCount ≥ #{limit} then
                exit repeat
              end if
              set taskCount to taskCount + 1
            LIMIT_CHECK_SCRIPT
          end
        end

        def get_task_properties_script
          <<~GET_TASK_PROPERTIES_SCRIPT
            set taskName to name of aToDo
            set taskNotes to notes of aToDo
            set taskStatus to status of aToDo
            set taskProject to ""
            set taskArea to ""
            set taskDueDate to ""
            set taskTags to ""

            try
              set taskProject to name of project of aToDo
            end try

            try
              set taskArea to name of area of aToDo
            end try

            try
              set taskDueDate to due date of aToDo as string
            end try

            try
              set taskTags to tag names of aToDo as string
            end try
          GET_TASK_PROPERTIES_SCRIPT
        end

        def add_task_info_script
          <<~ADD_TASK_INFO_SCRIPT
            #{get_task_properties_script}

            set taskInfo to "• " & taskName
            if taskStatus is not open then
              set taskInfo to taskInfo & " [" & taskStatus & "]"
            end if
            if taskProject is not "" then
              set taskInfo to taskInfo & " (Project: " & taskProject & ")"
            end if
            if taskArea is not "" then
              set taskInfo to taskInfo & " (Area: " & taskArea & ")"
            end if
            if taskDueDate is not "" then
              set taskInfo to taskInfo & " (Due: " & taskDueDate & ")"
            end if
            if taskTags is not "" then
              set taskInfo to taskInfo & " (Tags: " & taskTags & ")"
            end if
            if taskNotes is not "" then
              set taskInfo to taskInfo & "\\n  Notes: " & taskNotes
            end if

            set end of taskList to taskInfo
          ADD_TASK_INFO_SCRIPT
        end
      end
    end
  end
end
