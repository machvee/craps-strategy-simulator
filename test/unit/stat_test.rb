require 'test_helper'

class StatTest < ActiveSupport::TestCase
  def setup
     @s = Stat.new('wins')
  end

  def test_can_manually_incr_like_a_simple_counter
     @s.incr
     @s.incr
     @s.incr
     @s.incr
     assert_equal 4, @s.total
  end

  def test_can_use_like_won_lost
     @s.won
     @s.won
     @s.won
     @s.lost
     @s.won
     @s.lost
     @s.lost
     assert_equal 4, @s.total_won
     assert_equal 3, @s.total_lost
     assert_equal 3, @s.longest_winning_streak
     assert_equal 2, @s.longest_losing_streak

     assert_equal false, @s.last
     last_3 = @s.last(3)
     assert_equal [true, false, false], last_3 # won, lost, lost

     last_6 = @s.last(6)
     assert_equal [true, true, false, true, false, false], last_6 # reverse order of above won lost calls
  end

  def test_history
    @sh = Stat.new('bang', history_length: 5)
    @sh.won
    @sh.won
    @sh.won
    @sh.lost
    assert_equal 0, @sh.current_winning_streak
    assert_equal 1, @sh.current_losing_streak
    @sh.won
    @sh.won
    @sh.won
    assert_equal 3, @sh.current_winning_streak
    assert_equal 0, @sh.current_losing_streak
    assert_equal Stat::WON, @sh.last
    assert_equal [Stat::WON]*3, @sh.last(3)
    assert_equal [Stat::WON, Stat::LOST] + [Stat::WON]*3, @sh.last(5)
    @sh.lost
    assert_equal [Stat::LOST] + [Stat::WON]*3 + [Stat::LOST], @sh.last(5)
    assert_equal({Stat::WON => 3, Stat::LOST => 2}, @sh.last_counts)
  end

end
