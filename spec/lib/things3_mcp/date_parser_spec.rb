require 'spec_helper'

RSpec.describe Things3Mcp::DateParser do
  subject(:parser) { described_class.new }

  it 'parses ISO dates into components' do
    expect(parser.parse_natural_date('2026-09-30')).to include(year: 2026, month: 9, day: 30, iso: '2026-09-30')
  end

  it 'parses natural language' do
    result = parser.parse_natural_date('tomorrow')
    expect(result[:iso]).to eq((Date.today + 1).strftime('%Y-%m-%d'))
  end

  it 'returns keywords as symbols and nil for blank' do
    expect(parser.parse_natural_date('none')).to eq(:none)
    expect(parser.parse_natural_date('Someday')).to eq(:someday)
    expect(parser.parse_natural_date('anytime')).to eq(:anytime)
    expect(parser.parse_natural_date('  ')).to be_nil
    expect(parser.parse_natural_date(nil)).to be_nil
  end

  it 'raises on text it cannot understand' do
    expect { parser.parse_natural_date('blorp') }.to raise_error(described_class::UnparseableDate)
    expect { parser.parse_natural_date('2026-13-45') }.to raise_error(described_class::UnparseableDate)
  end
end
