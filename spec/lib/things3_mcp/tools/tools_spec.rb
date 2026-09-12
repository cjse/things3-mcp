require 'spec_helper'

RSpec.describe 'tools' do
  let(:executor) { FakeExecutor.new(*outputs) }
  let(:outputs) { [] }

  before do
    Things3Mcp.client = Things3Mcp::Client.new(executor, Things3Mcp::DateParser.new)
  end

  after { Things3Mcp.client = nil }

  it 'registers 20 tools with output schemas and annotations' do
    expect(Things3Mcp::Tools::ALL.size).to eq(20)
    Things3Mcp::Tools::ALL.each do |tool|
      h = tool.to_h
      expect(h[:outputSchema]).not_to be_nil, "#{tool.name_value} has no output schema"
      expect(h[:annotations]).to include(:readOnlyHint), "#{tool.name_value} has no annotations"
    end
    server = Things3Mcp::Server.build
    expect(server.tools.size).to eq(20)
  end

  describe Things3Mcp::Tools::GetTasksTool do
    let(:outputs) { [recs(rec('id1', 'One', 'open', '', 'P', '', 'a', '', '2026-09-09', '', ''), rec('id2', 'Two', 'completed', '', '', '', '', '', '', '', ''))] }

    it 'returns structured tasks and a text summary' do
      response = described_class.call(list: 'today', limit: 2)
      expect(response.error?).to be(false)
      expect(response.structured_content[:count]).to eq(2)
      expect(response.structured_content[:tasks][0]).to include(id: 'id1', project: 'P', tags: ['a'])
      expect(response.content.first[:text]).to include('- One (id: id1) | project: P | when: 2026-09-09 | tags: a')
      expect(response.content.first[:text]).to include('- Two (id: id2) | [completed]')
      expect(executor.scripts.first).to include('to dos of list "Today"')
    end
  end

  describe Things3Mcp::Tools::AddTaskTool do
    let(:outputs) { [rec('new1', 'Buy milk', 'open', '', '', '', '', '2026-09-30', '', '2026-09-08', '')] }

    it 'creates the task and passes parsed dates to the generator' do
      response = described_class.call(title: 'Buy milk', due_date: '2026-09-30')
      expect(response.structured_content).to include(id: 'new1', due_date: '2026-09-30')
      expect(executor.scripts.first).to include('set due date of t to my mkDate(2026, 9, 30)')
    end

    it 'reports an unparseable date as a tool error' do
      response = described_class.call(title: 'x', due_date: 'blorp')
      expect(response.error?).to be(true)
      expect(response.content.first[:text]).to include('Could not understand date')
      expect(executor.scripts).to be_empty
    end
  end

  describe Things3Mcp::Tools::GetTaskTool do
    let(:outputs) { [Things3Mcp::AppleScript::Executor::AppleScriptError.new('Task not found: nope')] }

    it 'turns AppleScript errors into error responses' do
      response = described_class.call(task_id: 'nope')
      expect(response.error?).to be(true)
      expect(response.content.first[:text]).to eq('Task not found: nope')
    end
  end

  describe Things3Mcp::Tools::GetProjectTool do
    let(:outputs) do
      [rec('p1', 'Proj', 'open', '', 'Work', '', '', '', '', '1'),
       recs(rec('t1', 'Task', 'open', '', 'Proj', '', '', '', '', '', ''))]
    end

    it 'nests the open tasks under the project' do
      response = described_class.call(project_id: 'Proj')
      expect(response.structured_content[:tasks].size).to eq(1)
      expect(response.content.first[:text]).to include("Proj (id: p1) | area: Work | 1 open to dos\n- Task (id: t1)")
    end
  end

  describe Things3Mcp::Tools::GetTagsTool do
    let(:outputs) { [recs(rec('g1', 'errand', 'context'), rec('g2', 'context', ''))] }

    it 'lists tags with parents' do
      response = described_class.call
      expect(response.structured_content[:tags]).to eq([{ id: 'g1', name: 'errand', parent: 'context' }, { id: 'g2', name: 'context', parent: nil }])
      expect(response.content.first[:text]).to eq("- errand (parent: context)\n- context")
    end
  end

  describe 'server dispatch' do
    let(:outputs) { [recs(rec('a1', 'Home', ''))] }

    it 'serves tools/call through MCP::Server with structured content' do
      server = Things3Mcp::Server.build
      result = server.handle_json({ jsonrpc: '2.0', id: 1, method: 'tools/call', params: { name: 'get_areas', arguments: {} } }.to_json)
      parsed = JSON.parse(result)
      expect(parsed.dig('result', 'structuredContent', 'areas', 0, 'name')).to eq('Home')
      expect(parsed.dig('result', 'isError')).to be(false)
    end

    it 'rejects missing required arguments before running AppleScript' do
      server = Things3Mcp::Server.build
      result = JSON.parse(server.handle_json({ jsonrpc: '2.0', id: 1, method: 'tools/call', params: { name: 'get_task', arguments: {} } }.to_json))
      expect(result.dig('result', 'isError')).to be(true)
      expect(executor.scripts).to be_empty
    end
  end
end
