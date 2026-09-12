require 'spec_helper'

RSpec.describe Things3Mcp::AppleScript::Generator::Projects do
  it 'lists projects with filters' do
    script = described_class.list_script(area: 'Work', status: 'open', tag: 't', search: 'x', limit: 2)
    expect(script).to include('repeat with x in (projects)')
    expect(script).to include('my areaName(x) is "Work"')
    expect(script).to include('status of x is open')
    expect(script).to include('if n ≥ 2 then exit repeat')
    expect(script).to include('my projectRecord(x)')
  end

  it 'creates a project in an area with dates and tags' do
    script = described_class.add_script(name: 'P', area: 'Work', tags: ['a'], due_date: { year: 2026, month: 1, day: 2 }, start_date: :someday)
    expect(script).to include('set p to make new project with properties {name:"P"}')
    expect(script).to include('set area of p to my findArea("Work")')
    expect(script).to include('set due date of p to my mkDate(2026, 1, 2)')
    expect(script).to include('move p to list "Someday"')
    expect(script).to include('set tag names of p to "a"')
  end

  it 'refuses to remove a project from its area' do
    expect { described_class.update_script('P', area: 'none') }.to raise_error(ArgumentError, /cannot remove a project/)
  end

  it 'lists the open to dos of a project' do
    script = described_class.tasks_script('P')
    expect(script).to include('set p to my findProject("P")')
    expect(script).to include('repeat with x in (to dos of p)')
    expect(script).to include('status of x is open')
  end

  it 'deletes and returns the record' do
    expect(described_class.delete_script('P')).to include('set rec to my projectRecord(p)').and include("delete p\n")
  end
end

RSpec.describe Things3Mcp::AppleScript::Generator::Areas do
  it 'lists, adds, renames, and deletes areas' do
    expect(described_class.list_script).to include('repeat with x in (areas)').and include('my areaRecord(x)')
    expect(described_class.add_script(name: 'Home', tags: ['t'])).to include('make new area with properties {name:"Home"}').and include('set tag names of a to "t"')
    expect(described_class.update_script('Home', name: 'House')).to include('set a to my findArea("Home")').and include('set name of a to "House"')
    expect(described_class.delete_script('Home')).to include("delete a\n")
  end
end

RSpec.describe Things3Mcp::AppleScript::Generator::Tags do
  it 'lists, adds with a parent, re-parents, and deletes tags' do
    expect(described_class.list_script).to include('repeat with x in (tags)').and include('my tagRecord(x)')
    expect(described_class.add_script(name: 'errand', parent: 'context')).to include('make new tag with properties {name:"errand"}').and include('set parent tag of g to my findTag("context")')
    expect(described_class.update_script('errand', parent: 'none')).to include('set parent tag of g to missing value')
    expect(described_class.delete_script('errand')).to include("delete g\n")
  end
end
