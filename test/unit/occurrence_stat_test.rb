require 'test_helper'

class OccurrenceStatTest < ActiveSupport::TestCase
  def test_can_reset_and_count_correctly_no_not_occurred
     vals = %w{red red blue blue blue red red blue blue red red red red}
     @val = nil
     @name = 'reds'
     red_count = vals.grep(/red/).length
     blue_count = vals.grep(/blue/).length
     s = OccurrenceStat.new(@name) {@val == 'red'}
     assert_equal @name, s.name
     assert_counts?(s, 0, 0, 0, 0)
     vals.each {|v| @val = v; s.update}
     assert_counts?(s, red_count, blue_count, 4, 3)
     s.reset
     assert_counts?(s, 0, 0, 0, 0)
  end

  def test_can_reset_and_count_correctly_with_not_occurred_condition
     vals  = %w{red red green blue yellow blue blue red yellow red blue
                blue red red red green red blue red}
     @val = nil
     @name = 'reds_vs_blue'
     red_count = vals.grep(/red/).length
     blue_count = vals.grep(/blue/).length
     s = OccurrenceStat.new(@name, lost_condition: equals_blue_proc) {@val == 'red'}
     assert_equal @name, s.name
     assert_counts?(s, 0, 0, 0, 0)
     vals.each {|v| @val = v; s.update}
     assert_counts?(s, red_count, blue_count, 4, 3)
     s.reset
     assert_counts?(s, 0, 0, 0, 0)
  end

  def test_prints_correctly
     vals  = %w{red red green blue yellow blue blue red yellow red blue
                blue red red red green red blue red}
     @val = nil
     @name = 'reds'
     red_count = vals.grep(/red/).length
     not_red_count = vals.length - red_count
     s = OccurrenceStat.new(@name) {@val == 'red'}
     assert_match %r{#@name,0,0,0.00,0,0,0.00,0}, s.to_s
     vals.each {|v| @val = v; s.update}
     assert_match %r{#@name,#{red_count + not_red_count},#{red_count}, 47.37,3,#{not_red_count}, 52.63,5}, s.to_s
  end

  def test_inspect_calls_to_s
    s = OccurrenceStat.new(@name) {@val == 'red'}
    s.expects(:attrs).once
    s.inspect
  end

  def test_history
    s = OccurrenceStat.new('bang', lost_condition: proc {@val == 'blue'}, history_length: 5) {@val == 'red'}
    @val = 'red'
    s.update
    s.update
    s.update
    @val = 'blue'
    s.update
    assert_equal 0, s.current_winning_streak
    assert_equal 1, s.current_losing_streak
    @val = 'red'
    s.update
    s.update
    s.update
    assert_equal 3, s.current_winning_streak
    assert_equal 0, s.current_losing_streak
    assert_equal Stat::WON, s.last
    assert_equal [Stat::WON]*3, s.last(3)
    assert_equal [Stat::WON, Stat::LOST] + [Stat::WON]*3, s.last(5)
    @val = 'blue'
    s.update
    assert_equal [Stat::LOST] + [Stat::WON]*3 + [Stat::LOST], s.last(5)
    assert_equal({Stat::WON => 3, Stat::LOST => 2}, s.last_counts)
  end

  def equals_blue_proc
    proc {@val == 'blue'}
  end

  def assert_counts?(s, otot, dnotot, omax, dnomax)
    assert_equal otot+dnotot, s.count
    assert_equal otot, s.total_won
    assert_equal otot, s.total(Stat::WON)
    assert_equal dnotot, s.total(Stat::LOST)
    assert_equal omax, s.longest_winning_streak
    assert_equal omax, s.longest_streak[Stat::WON]
    assert_equal dnomax, s.longest_streak[Stat::LOST]
  end
end
