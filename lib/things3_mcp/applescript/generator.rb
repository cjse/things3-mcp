# frozen_string_literal: true

module Things3Mcp
  module AppleScript
    class Generator
      def self.escape_quotes(str)
        return '' if str.nil?
        str.to_s.force_encoding('UTF-8').gsub('"', '\\"')
      end

      def self.add_task_script(name:, notes: nil, project: nil, area: nil, due_date: nil, start_date: nil, tags: [])
        script = <<~APPLESCRIPT
          tell application "Things3"
            set newToDo to make new to do with properties {name:"#{escape_quotes(name)}"#{notes ? %Q[, notes:"#{escape_quotes(notes)}"] : ""}}
            
            #{if project
              <<~PROJECT_SCRIPT
                try
                  set targetProject to first project whose name is "#{escape_quotes(project)}"
                  move newToDo to targetProject
                on error
                  -- Project doesn't exist, task will stay in inbox
                end try
              PROJECT_SCRIPT
            elsif area
              <<~AREA_SCRIPT
                try
                  set targetArea to first area whose name is "#{escape_quotes(area)}"
                  move newToDo to targetArea
                on error
                  -- Area doesn't exist, task will stay in inbox
                end try
              AREA_SCRIPT
            end}
            
            #{if start_date
              <<~START_DATE_SCRIPT
                try
                  set activation date of newToDo to date "#{start_date[:parsed_date]}"
                on error
                  -- Invalid start date format
                end try
              START_DATE_SCRIPT
            end}
            
            #{if due_date
              <<~DUE_DATE_SCRIPT
                try
                  set due date of newToDo to date "#{due_date[:parsed_date]}"
                on error
                  -- Invalid date format
                end try
              DUE_DATE_SCRIPT
            end}
            
            #{tags.map { |tag|
              <<~TAG_SCRIPT
                set tag names of newToDo to (tag names of newToDo) & "#{escape_quotes(tag)}"
              TAG_SCRIPT
            }.join}
            
            result_parts = ["Task created: " & name of newToDo]
            #{if start_date
              'set end of result_parts to "Start: ' + start_date[:parsed_date] + '"'
            end}
            #{if due_date
              'set end of result_parts to "Due: ' + due_date[:parsed_date] + '"'
            end}
            
            return result_parts as string
          end tell
        APPLESCRIPT

        script
      end

      def self.list_tasks_script(list_type:, project_filter: nil, area_filter: nil, tag_filter: nil, limit: nil)
        list_name = case list_type
                    when "inbox" then "Inbox"
                    when "today" then "Today"
                    when "upcoming" then "Upcoming"
                    when "anytime" then "Anytime"
                    when "someday" then "Someday"
                    when "completed" then nil # Special case
                    when "canceled" then nil  # Special case
                    when "all" then nil      # Special case
                    end

        <<~APPLESCRIPT
          tell application "Things3"
            set taskList to {}
            set taskCount to 0
            
            #{if list_type == "completed"
              'set theTasks to completed to dos'
            elsif list_type == "canceled"
              'set theTasks to canceled to dos'
            elsif list_type == "all"
              'set theTasks to to dos'
            else
              %Q[set theTasks to to dos of list "#{list_name}"]
            end}
            
            #{if project_filter
              <<~PROJECT_FILTER
                set filteredTasks to {}
                repeat with aToDo in theTasks
                  try
                    if name of project of aToDo is "#{escape_quotes(project_filter)}" then
                      set end of filteredTasks to aToDo
                    end if
                  end try
                end repeat
                set theTasks to filteredTasks
              PROJECT_FILTER
            elsif area_filter
              <<~AREA_FILTER
                set filteredTasks to {}
                repeat with aToDo in theTasks
                  try
                    if name of area of aToDo is "#{escape_quotes(area_filter)}" then
                      set end of filteredTasks to aToDo
                    end if
                  end try
                end repeat
                set theTasks to filteredTasks
              AREA_FILTER
            end}
            
            #{if tag_filter
              <<~TAG_FILTER
                set filteredTasks to {}
                repeat with aToDo in theTasks
                  try
                    if "#{escape_quotes(tag_filter)}" is in tag names of aToDo then
                      set end of filteredTasks to aToDo
                    end if
                  end try
                end repeat
                set theTasks to filteredTasks
              TAG_FILTER
            end}
            
            repeat with aToDo in theTasks
              #{if limit
                <<~LIMIT_CHECK
                  if taskCount ≥ #{limit} then
                    exit repeat
                  end if
                  set taskCount to taskCount + 1
                LIMIT_CHECK
              end}
              
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
              
              set taskInfo to "• " & taskName
              if taskStatus is not "open" then
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
            end repeat
            
            if length of taskList is 0 then
              return "No tasks found in #{list_type} list"
            else
              return taskList as string
            end if
          end tell
        APPLESCRIPT
      end

      def self.complete_task_script(task_id:)
        <<~APPLESCRIPT
          tell application "Things3"
            try
              set foundTask to first to do whose name is "#{escape_quotes(task_id)}" and status is "open"
              set status of foundTask to completed
              return "✅ Completed: " & name of foundTask
            on error
              return "❌ Task not found or already completed: #{escape_quotes(task_id)}"
            end try
          end tell
        APPLESCRIPT
      end

      def self.update_task_script(task_id:, title: nil, notes: nil, project: nil, area: nil, 
                                 due_date: nil, start_date: nil, deadline: nil, tags: nil)
        <<~APPLESCRIPT
          tell application "Things3"
            try
              set foundTask to first to do whose name is "#{escape_quotes(task_id)}" and status is "open"
              set updateList to {}
              
              #{if title
                <<~NAME_UPDATE
                  set name of foundTask to "#{escape_quotes(title)}"
                  set end of updateList to "title"
                NAME_UPDATE
              end}
              
              #{if notes
                <<~NOTES_UPDATE
                  set notes of foundTask to "#{escape_quotes(notes)}"
                  set end of updateList to "notes"
                NOTES_UPDATE
              end}
              
              #{if project
                if project == "none"
                  <<~REMOVE_PROJECT
                    try
                      move foundTask to list "Inbox"
                      set end of updateList to "removed from project"
                    end try
                  REMOVE_PROJECT
                else
                  <<~SET_PROJECT
                    try
                      set targetProject to first project whose name is "#{escape_quotes(project)}"
                      move foundTask to targetProject
                      set end of updateList to "moved to project #{escape_quotes(project)}"
                    on error
                      set end of updateList to "project '#{escape_quotes(project)}' not found"
                    end try
                  SET_PROJECT
                end
              end}
              
              #{if area
                if area == "none"
                  <<~REMOVE_AREA
                    try
                      move foundTask to list "Inbox"
                      set end of updateList to "removed from area"
                    end try
                  REMOVE_AREA
                else
                  <<~SET_AREA
                    try
                      set targetArea to first area whose name is "#{escape_quotes(area)}"
                      move foundTask to targetArea
                      set end of updateList to "moved to area #{escape_quotes(area)}"
                    on error
                      set end of updateList to "area '#{escape_quotes(area)}' not found"
                    end try
                  SET_AREA
                end
              end}
              
              #{if start_date
                <<~SET_START_DATE
                  try
                    set activation date of foundTask to date "#{start_date[:parsed_date]}"
                    set end of updateList to "set start date"
                  on error
                    set end of updateList to "invalid start date format"
                  end try
                SET_START_DATE
              end}
              
              #{if due_date
                <<~SET_DUE_DATE
                  try
                    set due date of foundTask to date "#{due_date[:parsed_date]}"
                    set end of updateList to "set due date"
                  on error
                    set end of updateList to "invalid due date format"
                  end try
                SET_DUE_DATE
              end}
              
              #{if deadline
                <<~SET_DEADLINE
                  try
                    set deadline of foundTask to date "#{deadline[:parsed_date]}"
                    set end of updateList to "set deadline"
                  on error
                    set end of updateList to "invalid deadline format"
                  end try
                SET_DEADLINE
              end}
              
              #{if tags
                <<~SET_TAGS
                  set tag names of foundTask to {#{tags.map { |tag| %Q["#{escape_quotes(tag)}"] }.join(", ")}}
                  set end of updateList to "updated tags"
                SET_TAGS
              end}
              
              if length of updateList is 0 then
                return "❓ No changes specified for task: #{escape_quotes(task_id)}"
              else
                return "✏️ Updated '" & name of foundTask & "'"
              end if
              
            on error
              return "❌ Task not found: #{escape_quotes(task_id)}"
            end try
          end tell
        APPLESCRIPT
      end

      def self.delete_task_script(task_id:)
        <<~APPLESCRIPT
          tell application "Things3"
            try
              set foundTask to first to do whose name is "#{escape_quotes(task_id)}"
              set taskName to name of foundTask
              delete foundTask
              return "🗑️ Deleted task: " & taskName
            on error
              return "❌ Task not found: #{escape_quotes(task_id)}"
            end try
          end tell
        APPLESCRIPT
      end

      def self.move_task_script(task_id:, destination:, destination_type:)
        case destination_type
        when "project"
          <<~APPLESCRIPT
            tell application "Things3"
              try
                set foundTask to first to do whose name is "#{escape_quotes(task_id)}" and status is "open"
                set targetProject to first project whose name is "#{escape_quotes(destination)}"
                move foundTask to targetProject
                return "📁 Moved '" & name of foundTask & "' to project: #{escape_quotes(destination)}"
              on error errorMsg
                if errorMsg contains "Can't get project" then
                  return "❌ Project not found: #{escape_quotes(destination)}"
                else
                  return "❌ Task not found: #{escape_quotes(task_id)}"
                end if
              end try
            end tell
          APPLESCRIPT
        when "area"
          <<~APPLESCRIPT
            tell application "Things3"
              try
                set foundTask to first to do whose name is "#{escape_quotes(task_id)}" and status is "open"
                set targetArea to first area whose name is "#{escape_quotes(destination)}"
                move foundTask to targetArea
                return "🏷️ Moved '" & name of foundTask & "' to area: #{escape_quotes(destination)}"
              on error errorMsg
                if errorMsg contains "Can't get area" then
                  return "❌ Area not found: #{escape_quotes(destination)}"
                else
                  return "❌ Task not found: #{escape_quotes(task_id)}"
                end if
              end try
            end tell
          APPLESCRIPT
        end
      end
    end
  end
end