require 'spec_helper'

RSpec.describe Things3Mcp::RecordParser do
  let(:fields) { Things3Mcp::AppleScript::Generator::Common::TASK_FIELDS }

  it 'parses several records into hashes' do
    text = recs(
      rec('id1', 'Task one', 'open', '', 'Proj', '', 'a, b', '2026-09-30', '', '2026-09-01', ''),
      rec('id2', 'Task two', 'completed', 'note\\nline 2', '', 'Area', '', '', '2026-09-02', '2026-09-01', '2026-09-03')
    ) + "\n"
    tasks = described_class.parse_many(text, fields)
    expect(tasks.size).to eq(2)
    expect(tasks[0]).to include(id: 'id1', name: 'Task one', status: 'open', project: 'Proj', area: nil,
                                tags: %w[a b], due_date: '2026-09-30', start_date: nil, completion_date: nil)
    expect(tasks[1]).to include(notes: "note\nline 2", tags: [], area: 'Area', completion_date: '2026-09-03')
  end

  it 'returns an empty array for empty output' do
    expect(described_class.parse_many("\n", fields)).to eq([])
  end

  it 'keeps trailing empty fields and converts task_count' do
    project = described_class.parse_one(rec('p1', 'P', 'open', '', '', '', '', '', '', '3'),
                                        Things3Mcp::AppleScript::Generator::Common::PROJECT_FIELDS)
    expect(project[:task_count]).to eq(3)
    expect(project[:creation_date]).to be_nil
  end
end
