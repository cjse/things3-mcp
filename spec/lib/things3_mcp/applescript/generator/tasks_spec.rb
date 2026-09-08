require 'spec_helper'

RSpec.describe Things3Mcp::AppleScript::Generator::Tasks do
  let(:date) { { year: 2026, month: 9, day: 30 } }

  describe '.add_script' do
    it 'creates a to do with name and notes' do
      script = described_class.add_script(name: 'Test Task', notes: 'Some notes')
      expect(script).to include('tell application "Things3"')
      expect(script).to include('set t to make new to do with properties {name:"Test Task", notes:"Some notes"}')
      expect(script).to include('return my taskRecord(t)')
      expect(script).to include('on taskRecord(t)')
    end

    it 'escapes quotes, backslashes, and newlines' do
      script = described_class.add_script(name: 'Say "hi"', notes: "a\\b\nline two")
      expect(script).to include('name:"Say \\"hi\\""')
      expect(script).to include('notes:"a\\\\b\\nline two"')
    end

    it 'assigns the project through the project property' do
      script = described_class.add_script(name: 'T', project: 'My Project')
      expect(script).to include('set project of t to my findProject("My Project")')
      expect(script).not_to include('move t to')
    end

    it 'assigns an area and a list together' do
      script = described_class.add_script(name: 'T', area: 'Work', list: 'today')
      expect(script).to include('set area of t to my findArea("Work")')
      expect(script).to include('move t to list "Today"')
    end

    it 'prefers project over area' do
      script = described_class.add_script(name: 'T', project: 'P', area: 'A')
      expect(script).to include('findProject("P")')
      expect(script).not_to include('findArea("A")')
    end

    it 'schedules a start date and sets a due date from components' do
      script = described_class.add_script(name: 'T', start_date: date, due_date: { year: 2026, month: 10, day: 1 })
      expect(script).to include('schedule t for my mkDate(2026, 9, 30)')
      expect(script).to include('set due date of t to my mkDate(2026, 10, 1)')
    end

    it 'sets tag names as a comma-separated string' do
      script = described_class.add_script(name: 'T', tags: ['a', ' b ', ''])
      expect(script).to include('set tag names of t to "a, b"')
    end

    it 'moves to Someday or Anytime for the keyword start dates' do
      expect(described_class.add_script(name: 'T', start_date: :someday)).to include('move t to list "Someday"')
      expect(described_class.add_script(name: 'T', start_date: :anytime)).to include('move t to list "Anytime"')
      expect(described_class.add_script(name: 'T', start_date: :none)).to include('move t to list "Anytime"')
    end

    it 'refuses to clear a deadline' do
      expect { described_class.add_script(name: 'T', due_date: :none) }.to raise_error(ArgumentError, /cannot clear a deadline/)
    end
  end

  describe '.update_script' do
    it 'finds the task and changes only the given fields' do
      script = described_class.update_script('abc', name: 'New', status: 'canceled')
      expect(script).to include('set t to my findTask("abc")')
      expect(script).to include('set name of t to "New"')
      expect(script).to include('set status of t to canceled')
      expect(script).not_to include('set notes of t')
      expect(script).not_to include('set tag names')
    end

    it 'moves the task to the Inbox for project "none"' do
      expect(described_class.update_script('abc', project: 'none')).to include('move t to list "Inbox"')
    end

    it 'ignores unknown statuses' do
      expect(described_class.update_script('abc', status: 'weird')).not_to include('set status')
    end
  end

  describe '.list_script' do
    it 'defaults to the Today list' do
      expect(described_class.list_script).to include('repeat with x in (to dos of list "Today")')
    end

    it 'maps list keys to Things list names' do
      expect(described_class.list_script(list: 'logbook')).to include('to dos of list "Logbook"')
      expect(described_class.list_script(list: 'all')).to include('repeat with x in (to dos)')
    end

    it 'uses the project as the source when no list is given' do
      script = described_class.list_script(project: 'P', tag: 'urgent')
      expect(script).to include('repeat with x in (to dos of my findProject("P"))')
      expect(script).to include('if ("urgent" is in tag names of x) then')
    end

    it 'filters inside a list with project, area, search, and status' do
      script = described_class.list_script(list: 'today', project: 'P', area: 'A', search: 'foo', status: 'open')
      expect(script).to include('my projectName(x) is "P"')
      expect(script).to include('my areaName(x) is "A"')
      expect(script).to include('name of x contains "foo"')
      expect(script).to include('status of x is open')
    end

    it 'stops at the limit' do
      expect(described_class.list_script(limit: 5)).to include('if n ≥ 5 then exit repeat')
      expect(described_class.list_script).not_to include('exit repeat')
    end
  end

  describe 'single-task scripts' do
    it 'completes, deletes, and moves by reference' do
      expect(described_class.complete_script('x')).to include('set status of t to completed')
      delete = described_class.delete_script('x')
      expect(delete).to include('set rec to my taskRecord(t)').and include("delete t\n").and include('return rec')
      expect(described_class.move_script('x', destination: 'P', destination_type: 'project')).to include('set project of t to my findProject("P")')
      expect(described_class.move_script('x', destination: 'A', destination_type: 'area')).to include('set area of t to my findArea("A")')
      expect(described_class.move_script('x', destination: 'someday', destination_type: 'list')).to include('move t to list "Someday"')
    end
  end
end
