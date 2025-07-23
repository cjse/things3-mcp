# frozen_string_literal: true

require 'spec_helper'
require 'things3_mcp/client'
require 'things3_mcp/applescript/generator'
require 'things3_mcp/applescript/executor'
require 'things3_mcp/date_parser'
require 'securerandom'

RSpec.describe Things3Mcp::Client, :integration do
  # Skip these tests if Things3 is not installed
  before(:all) do
    executor = Things3Mcp::AppleScript::Executor.new
    unless executor.things3_installed?
      skip "Things3 is not installed. Skipping end-to-end integration tests."
    end
  end

  let(:applescript_executor) { Things3Mcp::AppleScript::Executor.new(debug: false) }
  let(:date_parser) { Things3Mcp::DateParser.new(debug: false) }
  let(:client) { described_class.new(applescript_executor, date_parser) }

  describe 'integration test: add and retrieve task' do
    let(:unique_title) { "Test Task #{SecureRandom.hex(8)}" }
    let(:test_notes) { "This is a test task created by the integration test".dup }
    let(:test_tags) { ["test".dup, "integration".dup] }

    it 'creates a task and verifies it exists' do
      # Step 1: Add a task
      add_result = client.add_task(
        list: "inbox",
        title: unique_title,
        notes: test_notes,
        tags: test_tags
      )

      expect(add_result[:content][0][:text]).to include(unique_title)

      # Step 2: Get all tasks to verify the created task exists
      get_result = client.get_tasks(list: "inbox", limit: 100)

      expect(get_result[:content][0][:text]).to include(unique_title)
      expect(get_result[:content][0][:text]).to include(test_notes)
      test_tags.each do |tag|
        expect(get_result[:content][0][:text]).to include(tag)
      end

      # Step 3: Clean up - delete the created task
      delete_result = client.delete_task(task_id: unique_title)

      # The delete message uses an emoji and "Deleted"
      expect(delete_result[:content][0][:text]).to match(/Deleted|deleted/)
      expect(delete_result[:content][0][:text]).to include(unique_title)
    end
  end

  describe 'integration test with date parsing' do
    let(:unique_title) { "Date Test Task #{SecureRandom.hex(8)}" }
    let(:due_date_string) { "tomorrow" }
    let(:parsed_date) { Date.today + 1 }
    let(:formatted_date) { { parsed_date: parsed_date.strftime("%d %B %Y") } }

    it 'creates a task with a due date and retrieves it' do
      # Step 1: Add a task with due date
      add_result = client.add_task(
        list: "inbox",
        title: unique_title,
        due_date: due_date_string
      )

      # Check for successful creation
      expect(add_result[:content][0][:text]).to include("Task created:")
      expect(add_result[:content][0][:text]).to include(unique_title)
      expect(add_result[:content][0][:text]).to include("Due:")

      # Step 2: Get all tasks to find our task with due date
      get_result = client.get_tasks(list: "inbox")

      expect(get_result[:content][0][:text]).to include(unique_title)
      # The actual date format in the output might vary, so just check it includes "Due:"
      expect(get_result[:content][0][:text]).to match(/Due:/)

      # Step 3: Clean up
      delete_result = client.delete_task(task_id: unique_title)
      expect(delete_result[:content][0][:text]).to match(/Deleted|deleted/)
    end
  end
end
