require 'rails_helper'

describe TableState do
  before(:each) do
    @dice = double("dice")
    @shooter = double("shooter", done: nil)
    @table = double("table", dice: @dice, shooter: @shooter)
    @history_length = 5
  end

  it 'should have a nil point after initialize' do
    @table_state = TableState.new(@table, @history_length)
    expect(@table_state.point).to eq(nil)
  end

  it 'should be off after initialize' do
    @table_state = TableState.new(@table, @history_length)
    expect(@table_state.off?).to be true
  end

  it 'should be off and have a nil point after clear_point' do
    @table_state = TableState.new(@table, @history_length)
    @table_state.clear_point
    expect(@table_state.off?).to be true
    expect(@table_state.point).to eq(nil)
  end

  it 'should return the last_rolled value from dice' do
    @table_state = TableState.new(@table, @history_length)
    @value = 4
    allow(@dice).to receive(:value).and_return(@value)
    expect(@table_state.last_roll).to eq(@value)
  end

  it 'should clear the roll_counter and clear point when reset' do
    roll_counter = instance_double('Measure')
    expect(roll_counter).to receive(:reset).with(no_args)
    @table_state = TableState.new(@table, @history_length, frequency_counter: roll_counter)
    @table_state.reset
    expect(@table_state.off?).to be true
    expect(@table_state.point).to eq(nil)
  end

  it 'should commit the roll_counter and clear point when table is set off' do
    roll_counter = instance_double('Measure')
    expect(roll_counter).to receive(:commit).with(no_args)
    @table_state = TableState.new(@table, @history_length, frequency_counter: roll_counter)
    @table_state.table_off
    expect(@table_state.off?).to be true
    expect(@table_state.point).to eq(nil)
  end

  it 'should respond to table_on_with_point, setting current point and table state on, with new roll_counter' do
    @value = 9
    roll_counter = instance_double('Measure')
    expect(roll_counter).to receive(:reset).with(no_args)
    @table_state = TableState.new(@table, @history_length, frequency_counter: roll_counter)
    @table_state.table_on_with_point(@value)
    expect(@table_state.on?).to be true
    expect(@table_state.point).to eq(@value)
  end

  it 'should respond to seven_out when a 7 is rolled' do
    @table_state = TableState.new(@table, @history_length)
    @table_state.table_on_with_point(4)
    expect(@table_state.on?).to be true
    allow(@dice).to receive(:seven?).and_return(true)
    expect(@table_state.seven_out?).to be true
  end
  
  it 'should respond to point_established? when a point number rolled and table is off' do
    @table_state = TableState.new(@table, @history_length)
    @table_state.table_off
    allow(@dice).to receive_messages(
      value: 9,
      points?: true
    )
    expect(@table_state.point_established?).to be true
  end

  it 'should respond to point_established? false when a point number not and table is off' do
    @table_state = TableState.new(@table, @history_length)
    @table_state.table_off
    allow(@dice).to receive_messages(
      value: 3,
      points?: false
    )
    expect(@table_state.point_established?).to be false
  end

  it 'should respond to point_established?(9) when a point number rolled and table is off' do
    @table_state = TableState.new(@table, @history_length)
    @table_state.table_off
    allow(@dice).to receive_messages(
      value: 9,
      points?: true
    )
    expect(@table_state.point_established?(9)).to be true
  end

  it 'should respond false to point_established?(6) when a point number rolled and table is off' do
    @table_state = TableState.new(@table, @history_length)
    @table_state.table_off
    allow(@dice).to receive_messages(
      value: 9,
      points?: true
    )
    expect(@table_state.point_established?(6)).to be false
  end

  it 'should respond true to point_made? when a point number rolled and table is on' do
    @table_state = TableState.new(@table, @history_length)
    @table_state.table_on_with_point(4)
    allow(@dice).to receive_messages(
      value: 4
    )
    expect(@table_state.point_made?).to be true
  end

  it 'should respond true to point_made?(4) when a point number 4 rolled and table is on' do
    @table_state = TableState.new(@table, @history_length)
    @table_state.table_on_with_point(4)
    allow(@dice).to receive_messages(
      value: 4
    )
    expect(@table_state.point_made?(4)).to be true
  end

  it 'should respond false to point_made? when a non-point number rolled and table is on' do
    @table_state = TableState.new(@table, @history_length)
    @table_state.table_on_with_point(4)
    allow(@dice).to receive_messages(
      value: 3
    )
    expect(@table_state.point_made?).to be false
  end

  it 'should respond false to point_made?(4) when a point 5 number rolled and table is on' do
    @table_state = TableState.new(@table, @history_length)
    @table_state.table_on_with_point(4)
    allow(@dice).to receive_messages(
      value: 5
    )
    expect(@table_state.point_made?(4)).to be false
  end

  it 'should respond false to point_made?(5) when a point 4 number rolled and table is on' do
    @table_state = TableState.new(@table, @history_length)
    @table_state.table_on_with_point(4)
    allow(@dice).to receive_messages(
      value: 4
    )
    expect(@table_state.point_made?(5)).to be false
  end

  it 'should respond true to front_line_winner? when a winner rolled and table is off' do
    @table_state = TableState.new(@table, @history_length)
    @table_state.table_off
    allow(@dice).to receive_messages(
      winner?: true
    )
    expect(@table_state.front_line_winner?).to be true
  end

  it 'should respond false to front_line_winner? when a non-winner rolled and table is off' do
    @table_state = TableState.new(@table, @history_length)
    @table_state.table_off
    allow(@dice).to receive_messages(
      winner?: false
    )
    expect(@table_state.front_line_winner?).to be false
  end

  it 'should respond true to front_line_winner?(7) when a 7 rolled and table is off' do
    @table_state = TableState.new(@table, @history_length)
    @table_state.table_off
    allow(@dice).to receive_messages(
      value: 7,
      winner?: true
    )
    expect(@table_state.front_line_winner?(7)).to be true
    expect(@table_state.winner_seven?).to be true
  end

  it 'should respond false to front_line_winner?(7) when a 11 rolled and table is off' do
    @table_state = TableState.new(@table, @history_length)
    @table_state.table_off
    allow(@dice).to receive_messages(
      value: 11,
      winner?: true
    )
    expect(@table_state.front_line_winner?(7)).to be false
    expect(@table_state.yo_eleven?).to be true
  end

  it 'should respond true to crapped_out? when a craps rolled and table is off' do
    @table_state = TableState.new(@table, @history_length)
    @table_state.table_off
    allow(@dice).to receive_messages(
      craps?: true
    )
    expect(@table_state.crapped_out?).to be true
  end

  it 'should respond false to crapped_out? when a non-craps rolled and table is off' do
    @table_state = TableState.new(@table, @history_length)
    @table_state.table_off
    allow(@dice).to receive_messages(
      craps?: false
    )
    expect(@table_state.crapped_out?).to be false
  end

  it 'should update the table state to on given the table off and point number rolled then off when rolled again' do
    roll_counter = instance_double('Measure')
    expect(roll_counter).to receive(:reset).with(no_args)
    expect(roll_counter).to receive(:commit).with(no_args)
    @table_state = TableState.new(@table, @history_length, frequency_counter: roll_counter)
    allow(@dice).to receive_messages(
      value: 9,
      points?: true
    )
    @table_state.update
    expect(@table_state.on?).to be true
    expect(@table_state.point).to equal(9)
    @table_state.update
    expect(@table_state.off?).to be true
    expect(@table_state.point).to equal(nil)
  end

  it 'should set table off and invoke table callbacks when seven out' do
    roll_counter = instance_double('Measure')
    expect(roll_counter).to receive(:commit).with(no_args)
    expect(roll_counter).to receive(:reset).with(no_args)
    expect(@shooter).to receive(:done).with(no_args)
    expect(@table).to receive(:reset_player_strategies).with(no_args)

    @table_state = TableState.new(@table, @history_length, frequency_counter: roll_counter)
    @table_state.on(:seven_out) {|tbl| @shooter.done}
    @table_state.on(:seven_out) {|tbl| @table.reset_player_strategies}

    @table_state.table_on_with_point(4)
    expect(@table_state.on?).to be true
    expect(@table_state.point).to equal(4)

    allow(@dice).to receive_messages(
      seven?: true,
      value: 7,
      points?: false
    )
    @table_state.update
    expect(@table_state.off?).to be true
    expect(@table_state.point).to equal(nil)
  end
end
