require 'test_helper'

class BetPresserTest < ActiveSupport::TestCase
  def setup
    @player = mock('player')
    @bet_maker = mock('bet_maker', bet_short_name: 'place_bet')
    @bet_stats = mock('bet_stats')
    @stat = mock('stat')

    @bet_stats.expects(:stat_by_name).returns(@stat).at_least_once
    @player.expects(:bet_stats).at_least_once.returns(@bet_stats)

    @wins_start=31
    @stat.stubs(:total).returns(@wins_start)
    @bp = BetPresser.new(@player, @bet_maker)
  end

  def test_instance
    assert @bp
  end

  def test_sequence
    @amounts = [20,40,60,90,120]
    @bp.sequence(@amounts, @start_win = 2)
    assert_equal @amounts, @bp.amounts
    assert_equal @start_win, @bp.start_win
  end

  def test_incremental
    @incr = 6
    @bp.incremental(@incr, @start_win = 4)
    assert_equal @incr, @bp.press_unit
    assert_equal @start_win, @bp.start_win
  end

  def test_reset
    test_incremental
    @stat.unstub(:total)
    @stat.stubs(:total).returns(@wins_start+2)
    @bp.reset
    assert_equal @wins_start+2, @bp.start_win_count
  end

  def test_next_amount_sequence
    @amounts = [20,40,60,90,120]
    @bet = mock('bet')
    @bet.expects(:amount).at_least_once.returns(10)
    @bet_maker.expects(:bet).returns(@bet).at_least_once
    @bp.sequence(@amounts, 2)
    @stat.unstub(:total)
    @stat.stubs(:total).returns(@wins_start)
    assert_equal @bet.amount, @bp.next_bet_amount
    ([10,10] + @amounts).each_with_index do |a,i|
      @stat.unstub(:total)
      @stat.stubs(:total).returns(@wins_start+i)
      assert_equal a, @bp.next_bet_amount
    end
  end
end
