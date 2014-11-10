require 'test_helper'

class BetPresserTest < ActiveSupport::TestCase
  def setup
    @player = mock('player')
    @bet_stats = mock('bet_stats')
    @craps_bet = mock('craps_bet')
    @maker = mock('maker')
    @maker_stats = mock('maker_stats')
    @craps_bet.expects(:stat_name).returns('place_6').at_least_once
    @stat = mock('stat')

    @bet_stats.expects(:stat_by_name).returns(@stat).at_least_once
    @player.expects(:bet_stats).at_least_once.returns(@bet_stats)

    @wins_start=31
    @stat.stubs(:total).returns(@wins_start)
    @bp = BetPresser.new(@player, @maker, @craps_bet)
    @bp.amount_to_bet = 10
  end

  def test_instance
    assert @bp
  end

  def test_sequence
    @amounts = [20,40,60,90,120]
    @bp.sequence(@amounts)
    assert_equal @amounts, @bp.press_amounts
  end

  def test_incremental
    @incr = 6
    @start_win = 4
    @bp.incremental(@incr)
    @bp.start_pressing_at_win = @start_win
    assert_equal @incr, @bp.press_unit
    assert_equal @start_win, @bp.start_pressing_at_win
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
    @bp.sequence(@amounts)
    @bp.start_pressing_at_win = 2
    @stat.unstub(:total)
    @stat.stubs(:total).returns(@wins_start)
    @maker.expects(:stats).at_least_once.returns(@maker_stats)
    @maker_stats.expects(:press).at_least_once
    assert_equal @bp.amount_to_bet, @bp.next_bet_amount
    ([10,10] + @amounts).each_with_index do |a,i|
      @stat.unstub(:total)
      @stat.stubs(:total).returns(@wins_start+i)
      assert_equal a, @bp.next_bet_amount
    end
  end

  def test_next_amount_incremental
    @incr = 18
    @bp.incremental(@incr)
    @bp.start_pressing_at_win = 3
    @bp.stop_win = 6
    @stat.unstub(:total)
    @stat.stubs(:total).returns(@wins_start)
    @maker.expects(:stats).at_least_once.returns(@maker_stats)
    @maker_stats.expects(:press).at_least_once
    assert_equal @bp.amount_to_bet, @bp.next_bet_amount
    ([10,10,10,10+(@incr),10+(@incr*2),10+(@incr*3), 10+(@incr*3)]).each_with_index do |a,i|
      @stat.unstub(:total)
      @stat.stubs(:total).returns(@wins_start+i)
      assert_equal a, @bp.next_bet_amount
    end
  end
end
