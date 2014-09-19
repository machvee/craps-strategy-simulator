require 'test_helper'

class StatTest < ActiveSupport::TestCase
  def test_can_reset_and_count_correctly_no_not_occurred
     vals = %w{red red blue blue blue red red blue blue red red red red}
     @val = nil
     @name = 'reds'
     red_count = vals.grep(/red/).length
     blue_count = vals.grep(/blue/).length
     s = Stat.new(@name) {@val == 'red'}
     assert_equal @name, s.name
     assert_counts?(s, 0, 0, 0, 0)
     vals.each {|v| @val = v; s.update}
     assert_counts?(s, red_count, blue_count, 4, 3)
     s.reset
     assert_counts?(s, 0, 0, 0, 0)
  end

  def test_can_manually_incr_like_a_simple_counter
     s = Stat.new('wins')
     s.incr
     s.incr
     s.incr
     s.incr
     assert_equal 4, s.total
  end

  def test_can_manually_occur_not_occur
     s = Stat.new('wins')
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
     s = Stat.new(@name, equals_blue_proc) {@val == 'red'}
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
     s = Stat.new(@name) {@val == 'red'}
     assert_match %r{#@name,0,0,0,0,0}, s.to_s
     vals.each {|v| @val = v; s.update}
     assert_match %r{#@name,#{red_count + not_red_count},#{red_count},3,#{not_red_count},5}, s.to_s
  end

  def test_inspect_calls_to_s
    s = Stat.new(@name) {@val == 'red'}
    s.expects(:attrs).once
    s.inspect
  end

  def test_optional_counters
    s = Stat.new('bang', proc{}, counter_names: [:cats, :dogs])
    assert_equal({dogs: 0, cats: 0}, s.optional_counters.counters)
    s.won(dogs: 12)
    s.lost(cats: 33)
    s.won(dogs: 8, cats: 7)
    assert_equal 20, s.counters(:dogs)
    assert_equal 40, s.counters(:cats)
    s.reset
    assert_equal 0, s.counters(:dogs)
    assert_equal 0, s.counters(:cats)
    assert_raises RuntimeError do
      s.won(digs: 2)
    end
  end

  def test_history
    s = Stat.new('bang', proc {@val == 'blue'}, history_length: 5) {@val == 'red'}
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
