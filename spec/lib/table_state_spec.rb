require 'rails_helper'

describe TableState do
  before(:each) do
    @table = double("table")
    @history_length = 5
  end
  it 'should have a nil point after initialize' do
    table_state = TableState.new(@table, @history_length)
    expect(table_state.point).to eq(nil)
  end
end
