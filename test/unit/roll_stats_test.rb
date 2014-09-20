require 'test_helper'

class RollStatsTest < ActiveSupport::TestCase
  def setup
    @num_rolls = 397
    @d = Dice.new(2, DefaultSeeder.new(29293939))   # same roll sequence every time
    @dice_values = @d.gather(@num_rolls) # array of @num_rolls rolls of dice
    #
    # Roll stats will call table.last_roll [*2..12].length times
    # so build up the mock return values accordingly
    #
    value_range_length = [*@d.value_range].length
    @last_rolls = @dice_values.map {|v| [v]*value_range_length}.flatten
    @table = mock('table')
    dice_tray = mock('dice_tray')
    @table.expects(:dice_tray).once.returns(dice_tray)
    dice_tray.expects(:dice_value_range).once.returns(@d.value_range)
    @table.expects(:last_roll).at_least_once.returns(*@last_rolls)
    @r = RollStats.new('table dice roll', table: @table)
    @num_rolls.times {@r.update}
  end

  def test_convenience_methods
    assert_equal 2..12, @d.value_range
    [*@d.value_range].each do |value|
      assert_equal how_many(value), @r.send("rolled_#{value}".to_sym).total
    end
  end

  def how_many(value)
    @dice_values.select {|v| v == value}.length
  end
end
