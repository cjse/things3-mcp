require 'spec_helper'

RSpec.describe Things3Mcp::AppleScript::Generator do
  describe '.add_task_script' do
    it 'generates AppleScript for a simple task with just a name' do
      script = described_class.add_task_script(name: 'Test Task')

      expect(script).to include('tell application "Things3"')
      expect(script).to include('set theToDo to make new to do with properties {name:"Test Task"}')
      expect(script).to include('set result_parts to {"Task created: " & name of theToDo}')
      expect(script).to include('return result_parts as string')
      expect(script).to include('end tell')
    end

    it 'generates AppleScript for a task with notes' do
      script = described_class.add_task_script(
        name: 'Task with Notes',
        notes: 'These are the task notes'
      )

      expect(script).to include('set theToDo to make new to do with properties {name:"Task with Notes", notes:"These are the task notes"}')
    end

    it 'escapes quotes in task name and notes' do
      script = described_class.add_task_script(
        name: 'Task with "quotes"',
        notes: 'Notes with "quotes" too'
      )

      expect(script).to include('name:"Task with \\"quotes\\""')
      expect(script).to include('notes:"Notes with \\"quotes\\" too"')
    end

    it 'generates AppleScript for a task with a project' do
      script = described_class.add_task_script(
        name: 'Project Task',
        project: 'My Project'
      )

      expect(script).to include('set targetDestination to first project whose name is "My Project"')
      expect(script).to include('move theToDo to targetDestination')
    end

    it 'generates AppleScript for a task with an area' do
      script = described_class.add_task_script(
        name: 'Area Task',
        area: 'Work'
      )

      expect(script).to include('set targetDestination to first area whose name is "Work"')
      expect(script).to include('move theToDo to targetDestination')
    end

    it 'does not include both project and area (project takes precedence)' do
      script = described_class.add_task_script(
        name: 'Task',
        project: 'My Project',
        area: 'Work'
      )

      expect(script).to include('set targetDestination to first project whose name is "My Project"')
      expect(script).not_to include('set targetDestination to first area')
    end

    it 'generates AppleScript for a task with due date' do
      due_date = { parsed_date: '18 July 2025' }
      script = described_class.add_task_script(
        name: 'Task with Due Date',
        due_date: due_date
      )

      expect(script).to include('set due date of theToDo to date "18 July 2025"')
      expect(script).to include('set end of result_parts to "Due: 18 July 2025"')
    end

    it 'generates AppleScript for a task with start date' do
      start_date = { parsed_date: '17 July 2025' }
      script = described_class.add_task_script(
        name: 'Task with Start Date',
        start_date: start_date
      )

      expect(script).to include('schedule theToDo for date "17 July 2025"')
      expect(script).to include('set end of result_parts to "Start: 17 July 2025"')
    end

    it 'generates AppleScript for a task with tags' do
      script = described_class.add_task_script(
        name: 'Tagged Task',
        tags: ['urgent', 'work', 'important']
      )

      expect(script).to include('set tag names of theToDo to {"urgent", "work", "important"}')
    end

    it 'generates AppleScript for a task with all parameters' do
      due_date = { parsed_date: '20 July 2025' }
      start_date = { parsed_date: '18 July 2025' }

      script = described_class.add_task_script(
        name: 'Complete Task',
        notes: 'Task with everything',
        project: 'Big Project',
        due_date: due_date,
        start_date: start_date,
        tags: ['priority', 'review']
      )

      expect(script).to include('name:"Complete Task", notes:"Task with everything"')
      expect(script).to include('set targetDestination to first project whose name is "Big Project"')
      expect(script).to include('schedule theToDo for date "18 July 2025"')
      expect(script).to include('set due date of theToDo to date "20 July 2025"')
      expect(script).to include('set tag names of theToDo to {"priority", "review"}')
      expect(script).to include('set end of result_parts to "Start: 18 July 2025"')
      expect(script).to include('set end of result_parts to "Due: 20 July 2025"')
    end
  end

  describe '.complete_task_script' do
    it 'generates AppleScript to complete a task by name' do
      script = described_class.complete_task_script(task_id: 'My Task')

      expect(script).to include('tell application "Things3"')
      expect(script).to include('set theToDo to first to do whose name is "My Task" and status is open')
      expect(script).to include('set status of theToDo to completed')
      expect(script).to include('return "✅ Completed: " & name of theToDo')
      expect(script).to include('return "❌ Task not found or already completed: My Task"')
      expect(script).to include('end tell')
    end

    it 'escapes quotes in task name' do
      script = described_class.complete_task_script(task_id: 'Task with "quotes"')

      expect(script).to include('whose name is "Task with \\"quotes\\""')
      expect(script).to include('Task not found or already completed: Task with \\"quotes\\""')
    end

    it 'includes error handling for missing tasks' do
      script = described_class.complete_task_script(task_id: 'Non-existent Task')

      expect(script).to include('try')
      expect(script).to include('on error')
      expect(script).to include('return "❌ Task not found or already completed: Non-existent Task"')
      expect(script).to include('end try')
    end

    it 'only targets tasks with open status' do
      script = described_class.complete_task_script(task_id: 'Some Task')

      expect(script).to include('status is open')
      expect(script).not_to include('status is completed')
      expect(script).not_to include('status is canceled')
    end
  end

  describe '.delete_task_script' do
    it 'generates AppleScript to delete a task by name' do
      script = described_class.delete_task_script(task_id: 'Task to Delete')

      expect(script).to include('tell application "Things3"')
      expect(script).to include('set theToDo to first to do whose name is "Task to Delete"')
      expect(script).to include('set taskName to name of theToDo')
      expect(script).to include('delete theToDo')
      expect(script).to include('return "🗑️ Deleted task: " & taskName')
      expect(script).to include('return "❌ Task not found: Task to Delete"')
      expect(script).to include('end tell')
    end

    it 'escapes quotes in task name' do
      script = described_class.delete_task_script(task_id: 'Task "with quotes"')

      expect(script).to include('whose name is "Task \\"with quotes\\""')
      expect(script).to include('Task not found: Task \\"with quotes\\""')
    end

    it 'includes error handling for missing tasks' do
      script = described_class.delete_task_script(task_id: 'Missing Task')

      expect(script).to include('try')
      expect(script).to include('on error')
      expect(script).to include('return "❌ Task not found: Missing Task"')
      expect(script).to include('end try')
    end

    it 'can delete tasks regardless of status' do
      script = described_class.delete_task_script(task_id: 'Any Task')

      # Should not filter by status like complete_task does
      expect(script).not_to include('status is open')
      expect(script).not_to include('status is completed')
      expect(script).not_to include('status is canceled')
      # Should just find by name
      expect(script).to include('first to do whose name is "Any Task"')
    end

    it 'saves the task name before deletion' do
      script = described_class.delete_task_script(task_id: 'Task Name')

      # This ensures we capture the name before deleting, so we can report it
      expect(script).to match(/set taskName to name of theToDo.*delete theToDo/m)
    end
  end

  describe '.move_task_script' do
    context 'when moving to a project' do
      it 'generates AppleScript to move a task to a project' do
        script = described_class.move_task_script(
          task_id: 'My Task',
          destination: 'Work Project',
          destination_type: 'project'
        )

        expect(script).to include('tell application "Things3"')
        expect(script).to include('set theToDo to first to do whose name is "My Task" and status is open')
        expect(script).to include('set targetDestination to first project whose name is "Work Project"')
        expect(script).to include('move theToDo to targetDestination')
        expect(script).to include('return "📁 Moved \'" & name of theToDo & "\' to project: Work Project"')
        expect(script).to include('end tell')
      end

      it 'handles project not found error' do
        script = described_class.move_task_script(
          task_id: 'Task',
          destination: 'Missing Project',
          destination_type: 'project'
        )

        expect(script).to include('if errorMsg contains "Can\'t get project" then')
        expect(script).to include('return "❌ project not found: Missing Project"')
      end

      it 'handles task not found error' do
        script = described_class.move_task_script(
          task_id: 'Missing Task',
          destination: 'Project',
          destination_type: 'project'
        )

        expect(script).to include('else')
        expect(script).to include('return "❌ Task not found: Missing Task"')
      end
    end

    context 'when moving to an area' do
      it 'generates AppleScript to move a task to an area' do
        script = described_class.move_task_script(
          task_id: 'My Task',
          destination: 'Personal',
          destination_type: 'area'
        )

        expect(script).to include('tell application "Things3"')
        expect(script).to include('set theToDo to first to do whose name is "My Task" and status is open')
        expect(script).to include('set targetDestination to first area whose name is "Personal"')
        expect(script).to include('move theToDo to targetDestination')
        expect(script).to include('return "📁 Moved \'" & name of theToDo & "\' to area: Personal"')
        expect(script).to include('end tell')
      end

      it 'handles area not found error' do
        script = described_class.move_task_script(
          task_id: 'Task',
          destination: 'Missing Area',
          destination_type: 'area'
        )

        expect(script).to include('if errorMsg contains "Can\'t get area" then')
        expect(script).to include('return "❌ area not found: Missing Area"')
      end
    end

    it 'escapes quotes in task names and destinations' do
      script = described_class.move_task_script(
        task_id: 'Task "with quotes"',
        destination: 'Project "name"',
        destination_type: 'project'
      )

      expect(script).to include('whose name is "Task \\"with quotes\\""')
      expect(script).to include('whose name is "Project \\"name\\""')
      expect(script).to include('Task not found: Task \\"with quotes\\""')
      expect(script).to include('project not found: Project \\"name\\""')
      expect(script).to include('to project: Project \\"name\\""')
    end

    it 'only moves tasks with open status' do
      script = described_class.move_task_script(
        task_id: 'Task',
        destination: 'Destination',
        destination_type: 'project'
      )

      expect(script).to include('status is open')
      expect(script).not_to include('status is completed')
      expect(script).not_to include('status is canceled')
    end

    it 'includes proper error handling' do
      script = described_class.move_task_script(
        task_id: 'Task',
        destination: 'Dest',
        destination_type: 'area'
      )

      expect(script).to include('try')
      expect(script).to include('on error errorMsg')
      expect(script).to include('end try')
    end
  end

  describe '.list_tasks_script' do
    it 'generates AppleScript for listing tasks from inbox' do
      script = described_class.list_tasks_script(list_type: 'inbox')

      expect(script).to include('tell application "Things3"')
      expect(script).to include('set theTasks to to dos of list "Inbox"')
      expect(script).to include('set taskList to {}')
      expect(script).to include('set taskCount to 0')
      expect(script).to include('repeat with aToDo in theTasks')
      expect(script).to include('set taskName to name of aToDo')
      expect(script).to include('set end of taskList to taskInfo')
      expect(script).to include('return "No tasks found in inbox list"')
      expect(script).to include('return taskList as string')
      expect(script).to include('end tell')
    end

    it 'generates AppleScript for listing tasks from today list' do
      script = described_class.list_tasks_script(list_type: 'today')

      expect(script).to include('set theTasks to to dos of list "Today"')
      expect(script).to include('return "No tasks found in today list"')
    end

    it 'generates AppleScript for listing completed tasks' do
      script = described_class.list_tasks_script(list_type: 'completed')

      expect(script).to include('set theTasks to completed to dos')
      expect(script).not_to include('to dos of list')
      expect(script).to include('return "No tasks found in completed list"')
    end

    it 'generates AppleScript for listing canceled tasks' do
      script = described_class.list_tasks_script(list_type: 'canceled')

      expect(script).to include('set theTasks to canceled to dos')
      expect(script).not_to include('to dos of list')
      expect(script).to include('return "No tasks found in canceled list"')
    end

    it 'generates AppleScript for listing all tasks' do
      script = described_class.list_tasks_script(list_type: 'all')

      expect(script).to include('set theTasks to to dos')
      expect(script).not_to include('to dos of list')
      expect(script).not_to include('completed to dos')
      expect(script).not_to include('canceled to dos')
      expect(script).to include('return "No tasks found in all list"')
    end

    it 'includes task properties in output' do
      script = described_class.list_tasks_script(list_type: 'today')

      # Basic properties
      expect(script).to include('set taskName to name of aToDo')
      expect(script).to include('set taskNotes to notes of aToDo')
      expect(script).to include('set taskStatus to status of aToDo')

      # Optional properties with error handling
      expect(script).to include('try')
      expect(script).to include('set taskProject to name of project of aToDo')
      expect(script).to include('set taskArea to name of area of aToDo')
      expect(script).to include('set taskDueDate to due date of aToDo as string')
      expect(script).to include('set taskTags to tag names of aToDo as string')
      expect(script).to include('end try')
    end

    it 'formats task output correctly' do
      script = described_class.list_tasks_script(list_type: 'today')

      expect(script).to include('set taskInfo to "• " & taskName')
      expect(script).to include('if taskStatus is not open then')
      expect(script).to include('set taskInfo to taskInfo & " [" & taskStatus & "]"')
      expect(script).to include('if taskProject is not "" then')
      expect(script).to include('set taskInfo to taskInfo & " (Project: " & taskProject & ")"')
      expect(script).to include('if taskArea is not "" then')
      expect(script).to include('set taskInfo to taskInfo & " (Area: " & taskArea & ")"')
      expect(script).to include('if taskDueDate is not "" then')
      expect(script).to include('set taskInfo to taskInfo & " (Due: " & taskDueDate & ")"')
      expect(script).to include('if taskTags is not "" then')
      expect(script).to include('set taskInfo to taskInfo & " (Tags: " & taskTags & ")"')
      expect(script).to include('if taskNotes is not "" then')
      expect(script).to include('set taskInfo to taskInfo & "\\n  Notes: " & taskNotes')
    end

    context 'with project filter' do
      it 'generates AppleScript to filter tasks by project' do
        script = described_class.list_tasks_script(
          list_type: 'today',
          project_filter: 'Work Project'
        )

        expect(script).to include('set filteredTasks to {}')
        expect(script).to include('repeat with aToDo in theTasks')
        expect(script).to include('if name of project of aToDo is "Work Project" then')
        expect(script).to include('set end of filteredTasks to aToDo')
        expect(script).to include('set theTasks to filteredTasks')
      end

      it 'escapes quotes in project filter' do
        script = described_class.list_tasks_script(
          list_type: 'today',
          project_filter: 'Project "with quotes"'
        )

        expect(script).to include('if name of project of aToDo is "Project \\"with quotes\\""')
      end
    end

    context 'with area filter' do
      it 'generates AppleScript to filter tasks by area' do
        script = described_class.list_tasks_script(
          list_type: 'today',
          area_filter: 'Personal'
        )

        expect(script).to include('set filteredTasks to {}')
        expect(script).to include('repeat with aToDo in theTasks')
        expect(script).to include('if name of area of aToDo is "Personal" then')
        expect(script).to include('set end of filteredTasks to aToDo')
        expect(script).to include('set theTasks to filteredTasks')
      end

      it 'escapes quotes in area filter' do
        script = described_class.list_tasks_script(
          list_type: 'today',
          area_filter: 'Area "name"'
        )

        expect(script).to include('if name of area of aToDo is "Area \\"name\\""')
      end
    end

    context 'with tag filter' do
      it 'generates AppleScript to filter tasks by tag' do
        script = described_class.list_tasks_script(
          list_type: 'today',
          tag_filter: 'urgent'
        )

        expect(script).to include('set filteredTasks to {}')
        expect(script).to include('repeat with aToDo in theTasks')
        expect(script).to include('if "urgent" is in tag names of aToDo then')
        expect(script).to include('set end of filteredTasks to aToDo')
        expect(script).to include('set theTasks to filteredTasks')
      end

      it 'escapes quotes in tag filter' do
        script = described_class.list_tasks_script(
          list_type: 'today',
          tag_filter: 'tag "with quotes"'
        )

        expect(script).to include('if "tag \\"with quotes\\"" is in tag names of aToDo')
      end
    end

    context 'with limit' do
      it 'generates AppleScript to limit number of tasks' do
        script = described_class.list_tasks_script(
          list_type: 'today',
          limit: 10
        )

        expect(script).to include('if taskCount ≥ 10 then')
        expect(script).to include('exit repeat')
        expect(script).to include('set taskCount to taskCount + 1')
      end

      it 'handles different limit values' do
        script = described_class.list_tasks_script(
          list_type: 'inbox',
          limit: 5
        )

        expect(script).to include('if taskCount ≥ 5 then')
      end
    end

    it 'does not include filters when not specified' do
      script = described_class.list_tasks_script(list_type: 'today')

      expect(script).not_to include('set filteredTasks to {}')
      expect(script).not_to include('if taskCount ≥')
    end

    it 'only applies one filter at a time (project takes precedence)' do
      script = described_class.list_tasks_script(
        list_type: 'today',
        project_filter: 'Work',
        area_filter: 'Personal'
      )

      expect(script).to include('if name of project of aToDo is "Work"')
      expect(script).not_to include('if name of area of aToDo is "Personal"')
    end
  end

  describe '.update_task_script' do
    it 'generates AppleScript to find a task by name with open status' do
      script = described_class.update_task_script(task_id: 'My Task')

      expect(script).to include('tell application "Things3"')
      expect(script).to include('set theToDo to first to do whose name is "My Task" and status is open')
      expect(script).to include('set result_parts to {}')
      expect(script).to include('end tell')
    end

    it 'returns no changes message when no updates specified' do
      script = described_class.update_task_script(task_id: 'My Task')

      expect(script).to include('if length of result_parts is 0 then')
      expect(script).to include('return "❓ No changes specified for task \'My Task\'"')
    end

    it 'generates AppleScript to update task title' do
      script = described_class.update_task_script(
        task_id: 'Old Title',
        title: 'New Title'
      )

      expect(script).to include('set name of theToDo to "New Title"')
      expect(script).to include('set end of result_parts to "Updated name"')
      expect(script).to include('return "✏️ Updated \'" & name of theToDo & "\'"')
    end

    it 'generates AppleScript to update task notes' do
      script = described_class.update_task_script(
        task_id: 'My Task',
        notes: 'These are the new notes'
      )

      expect(script).to include('set notes of theToDo to "These are the new notes"')
      expect(script).to include('set end of result_parts to "notes"')
    end

    it 'escapes quotes in task id, title, and notes' do
      script = described_class.update_task_script(
        task_id: 'Task "with quotes"',
        title: 'New "title"',
        notes: 'Notes "with quotes"'
      )

      expect(script).to include('whose name is "Task \\"with quotes\\""')
      expect(script).to include('set name of theToDo to "New \\"title\\""')
      expect(script).to include('set notes of theToDo to "Notes \\"with quotes\\""')
      expect(script).to include('Task not found: Task \\"with quotes\\""')
    end

    context 'updating project' do
      it 'generates AppleScript to move task to a project' do
        script = described_class.update_task_script(
          task_id: 'My Task',
          project: 'Work Project'
        )

        expect(script).to include('try')
        expect(script).to include('set targetDestination to first project whose name is "Work Project"')
        expect(script).to include('move theToDo to targetDestination')
        expect(script).to include('set end of result_parts to "Moved to project \'Work Project\'"')
        expect(script).to include('on error')
        expect(script).to include('set end of result_parts to "Project \'Work Project\' not found"')
        expect(script).to include('end try')
      end

      it 'generates AppleScript to remove task from project' do
        script = described_class.update_task_script(
          task_id: 'My Task',
          project: 'none'
        )

        expect(script).to include('move theToDo to list "Inbox"')
        expect(script).to include('set end of result_parts to "removed from project"')
      end

      it 'escapes quotes in project name' do
        script = described_class.update_task_script(
          task_id: 'My Task',
          project: 'Project "name"'
        )

        expect(script).to include('whose name is "Project \\"name\\""')
        expect(script).to include('Moved to project \'Project \\"name\\"\'')
        expect(script).to include('Project \'Project \\"name\\"\' not found')
      end
    end

    context 'updating area' do
      it 'generates AppleScript to move task to an area' do
        script = described_class.update_task_script(
          task_id: 'My Task',
          area: 'Personal'
        )

        expect(script).to include('try')
        expect(script).to include('set targetDestination to first area whose name is "Personal"')
        expect(script).to include('move theToDo to targetDestination')
        expect(script).to include('set end of result_parts to "Moved to area \'Personal\'"')
        expect(script).to include('on error')
        expect(script).to include('set end of result_parts to "Area \'Personal\' not found"')
        expect(script).to include('end try')
      end

      it 'generates AppleScript to remove task from area' do
        script = described_class.update_task_script(
          task_id: 'My Task',
          area: 'none'
        )

        expect(script).to include('move theToDo to list "Inbox"')
        expect(script).to include('set end of result_parts to "removed from area"')
      end

      it 'escapes quotes in area name' do
        script = described_class.update_task_script(
          task_id: 'My Task',
          area: 'Area "name"'
        )

        expect(script).to include('whose name is "Area \\"name\\""')
        expect(script).to include('Moved to area \'Area \\"name\\"\'')
        expect(script).to include('Area \'Area \\"name\\"\' not found')
      end
    end

    context 'updating dates' do
      it 'generates AppleScript to update start date' do
        start_date = { parsed_date: '20 July 2025' }
        script = described_class.update_task_script(
          task_id: 'My Task',
          start_date: start_date
        )

        expect(script).to include('try')
        expect(script).to include('schedule theToDo for date "20 July 2025"')
        expect(script).to include('set end of result_parts to "Start: 20 July 2025"')
        expect(script).to include('on error')
        expect(script).to include('set end of result_parts to "Invalid start date format"')
        expect(script).to include('end try')
      end

      it 'generates AppleScript to update due date' do
        due_date = { parsed_date: '25 July 2025' }
        script = described_class.update_task_script(
          task_id: 'My Task',
          due_date: due_date
        )

        expect(script).to include('try')
        expect(script).to include('set due date of theToDo to date "25 July 2025"')
        expect(script).to include('set end of result_parts to "Due: 25 July 2025"')
        expect(script).to include('on error')
        expect(script).to include('set end of result_parts to "Invalid due date format"')
        expect(script).to include('end try')
      end
    end

    context 'updating tags' do
      it 'generates AppleScript to update tags' do
        script = described_class.update_task_script(
          task_id: 'My Task',
          tags: ['urgent', 'work', 'important']
        )

        expect(script).to include('set tag names of theToDo to {"urgent", "work", "important"}')
        expect(script).to include('set end of result_parts to "Updated tags"')
      end

      it 'escapes quotes in tag names' do
        script = described_class.update_task_script(
          task_id: 'My Task',
          tags: ['tag "one"', 'tag "two"']
        )

        expect(script).to include('set tag names of theToDo to {"tag \\"one\\"", "tag \\"two\\""}')
      end

      it 'generates AppleScript to clear tags with empty array' do
        script = described_class.update_task_script(
          task_id: 'My Task',
          tags: []
        )

        expect(script).to include('set tag names of theToDo to {}')
        expect(script).to include('set end of result_parts to "Updated tags"')
      end
    end

    it 'generates AppleScript to update multiple properties' do
      due_date = { parsed_date: '30 July 2025' }
      start_date = { parsed_date: '18 July 2025' }

      script = described_class.update_task_script(
        task_id: 'My Task',
        title: 'Updated Task',
        notes: 'Updated notes',
        project: 'New Project',
        due_date: due_date,
        start_date: start_date,
        tags: ['updated', 'multiple']
      )

      expect(script).to include('set name of theToDo to "Updated Task"')
      expect(script).to include('set notes of theToDo to "Updated notes"')
      expect(script).to include('set targetDestination to first project whose name is "New Project"')
      expect(script).to include('schedule theToDo for date "18 July 2025"')
      expect(script).to include('set due date of theToDo to date "30 July 2025"')
      expect(script).to include('set tag names of theToDo to {"updated", "multiple"}')
      expect(script).to include('return "✏️ Updated \'" & name of theToDo & "\'"')
    end

    it 'includes error handling for task not found' do
      script = described_class.update_task_script(
        task_id: 'Non-existent Task',
        title: 'New Title'
      )

      expect(script).to include('try')
      expect(script).to include('on error')
      expect(script).to include('return "❌ Task not found: Non-existent Task"')
      expect(script).to include('end try')
    end

    it 'only targets tasks with open status' do
      script = described_class.update_task_script(task_id: 'Some Task')

      expect(script).to include('status is open')
      expect(script).not_to include('status is completed')
      expect(script).not_to include('status is canceled')
    end
  end
end
