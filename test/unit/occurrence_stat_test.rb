require 'test_helper'

class OccurrenceStatTest < Test::Unit::TestCase
  def test_can_reset_and_count_correctly_no_guard
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
     assert_match %r{#@name *#{red_count} */ *3 *#{not_red_count} */ *5}, s.to_s
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
    assert_equal otot, s.total
    assert_equal otot, s.total(OccurrenceStat::OCCURRED)
    assert_equal dnotot, s.total(OccurrenceStat::DID_NOT_OCCUR)
    assert_equal omax, s.max
    assert_equal omax, s.max(OccurrenceStat::OCCURRED)
    assert_equal dnomax, s.max(OccurrenceStat::DID_NOT_OCCUR)
  end
end
