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

  def test_can_manually_incr_like_a_simple_counter
     s = OccurrenceStat.new('wins')
     s.incr
     s.incr
     s.incr
     s.incr
     assert_equal 4, s.total
  end

  def test_can_manually_occur_not_occur
     s = OccurrenceStat.new('wins')
     s.won
     s.won
     s.won
     s.lost
     s.won
     s.lost
     s.lost
     assert_equal 4, s.total_won
     assert_equal 3, s.total_lost
     assert_equal 3, s.longest_winning_streak
     assert_equal 2, s.longest_losing_streak

     assert_equal false, s.last
     last_3 = s.last(3)
     assert_equal [true, false, false], last_3 # won, lost, lost

     last_6 = s.last(6)
     assert_equal [true, true, false, true, false, false], last_6 # reverse order of above won lost calls
  end

  def test_can_reset_and_count_correctly_with_not_occurred_condition
     vals  = %w{red red green blue yellow blue blue red yellow red blue
                blue red red red green red blue red}
     @val = nil
     @name = 'reds_vs_blue'
     red_count = vals.grep(/red/).length
     blue_count = vals.grep(/blue/).length
     s = OccurrenceStat.new(@name, equals_blue_proc) {@val == 'red'}
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
     assert_match %r{#@name.*0 */ *0 *0 */ *0}, s.to_s
     vals.each {|v| @val = v; s.update}
     assert_match %r{#@name *#{red_count + not_red_count} *#{red_count} */ *3 *#{not_red_count} */ *5}, s.to_s
  end

  def test_inspect_calls_to_s
    s = OccurrenceStat.new(@name) {@val == 'red'}
    s.expects(:to_s).once
    s.inspect
  end

  def equals_blue_proc
    Proc.new {@val == 'blue'}
  end

  def assert_counts?(s, otot, dnotot, omax, dnomax)
    assert_equal otot+dnotot, s.count
    assert_equal otot, s.total_won
    assert_equal otot, s.total(OccurrenceStat::WON)
    assert_equal dnotot, s.total(OccurrenceStat::LOST)
    assert_equal omax, s.longest_winning_streak
    assert_equal omax, s.longest_streak[OccurrenceStat::WON]
    assert_equal dnomax, s.longest_streak[OccurrenceStat::LOST]
  end
end
