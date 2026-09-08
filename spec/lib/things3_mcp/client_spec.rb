# frozen_string_literal: true

require 'spec_helper'
require 'securerandom'

# End-to-end tests against the real Things 3 app. Every task they create is
# moved to the Trash at the end. Skipped when Things is not installed.
RSpec.describe Things3Mcp::Client, :integration do
  before(:all) do
    executor = Things3Mcp::AppleScript::Executor.new
    skip 'Things3 is not installed. Skipping end-to-end integration tests.' unless executor.things3_installed?
  end

  let(:client) { described_class.new(Things3Mcp::AppleScript::Executor.new, Things3Mcp::DateParser.new) }

  describe 'add, find, and delete a task' do
    let(:unique_title) { "Test Task #{SecureRandom.hex(8)}" }
    let(:test_notes) { "This is a test task created by the integration test\nwith a second line" }
    let(:test_tags) { %w[test integration] }

    it 'creates a task, finds it in the Inbox, and trashes it' do
      created = client.add_task(title: unique_title, notes: test_notes, tags: test_tags, list: 'inbox')
      expect(created).to include(name: unique_title, notes: test_notes, status: 'open')
      expect(created[:tags]).to match_array(test_tags)
      expect(created[:id]).to be_a(String)

      inbox = client.list_tasks(list: 'inbox', search: unique_title)
      expect(inbox.map { |t| t[:id] }).to include(created[:id])

      found = client.get_task(created[:id])
      expect(found).to include(name: unique_title, notes: test_notes)

      deleted = client.delete_task(created[:id])
      expect(deleted[:id]).to eq(created[:id])
      expect(client.list_tasks(list: 'trash', search: unique_title).map { |t| t[:id] }).to include(created[:id])
    end
  end

  describe 'dates' do
    let(:unique_title) { "Date Test Task #{SecureRandom.hex(8)}" }

    it 'sets a deadline and a start date from natural language' do
      created = client.add_task(title: unique_title, due_date: 'tomorrow', start_date: 'tomorrow', list: 'inbox')
      tomorrow = (Date.today + 1).strftime('%Y-%m-%d')
      expect(created).to include(due_date: tomorrow, start_date: tomorrow)
    ensure
      client.delete_task(unique_title) if created
    end
  end
end
