require 'test_helper'

class BetMakerTest < ActiveSupport::TestCase
  def setup
    @table = mock('table')
    @player = mock('player')
    @bet_stat = mock('bet_stat')
    @bet_box = mock('bet_box')
    @craps_bet = mock('craps_bet')
    @craps_bet.expects(:stat_name).at_least_once.returns('dontcare')
    @bet_box.expects(:craps_bet).at_least_once.returns(@craps_bet)
    @bet_stat.expects(:total).returns(20).at_least_once
    @bet_stats = mock('bet_stats')
    @bet_stats.expects(:stat_by_name).returns(@bet_stat).at_least_once
    @player.expects(:table).at_least_once.returns(@table)
    @player.expects(:bet_stats).at_least_once.returns(@bet_stats)
    @player.expects(:bet_unit).at_least_once.returns(10)
    @table.expects(:find_bet_box).at_least_once.with(AcesBet.short_name, nil).returns(@bet_box)
    @table.expects(:find_bet_box).at_least_once.with(PlaceBet.short_name, 10).returns(@bet_box)

    set_points

    @number = 10
    @bm = BetMaker.new(@player, AcesBet.short_name)
    @pbm = BetMaker.new(@player, PlaceBet.short_name, @number)

  end

  def test_instance
    assert @bm
  end

  def test_for
    assert_equal @bm, @bm.for(25)
  end

  def test_after_making_point_n
    assert_equal @bm, @bm.for(25).after_making_point(2)
  end

  def test_press_after_win_to
    assert_equal @pbm, @pbm.for(25).after_making_point(2).press_to(50,100,125,150).after_win(2)
  end

  def test_no_press_after_win
    assert_equal @pbm, @pbm.for(25).after_making_point(2).no_press_after_win(4)
  end

  def test_press_by_additional_after_win
    assert_equal @pbm, @pbm.for(25).after_making_point(2).press_by_additional(25).after_win(2)
  end

  def test_default_bet_amount
    assert_equal @pbm, @pbm.after_making_point(2).press_by_additional_bet_unit.after_win(2).no_press_after_win(5)
    assert_equal @player.bet_unit, @pbm.start_amount
    assert_equal @player.bet_unit, @pbm.bet_presser.amount_to_bet
  end

  def test_full_press_after_win
    assert_equal @pbm, @pbm.for(25).after_making_point(2).full_press.after_win(2).no_press_after_win(4)
  end

  private

  def set_points
    @stats = mock('tracking_stats')
    @stat = mock('passline point stat')
    @table.expects(:tracking_bet_stats).returns(@stats).at_least_once
    @stats.expects(:pass_line_point).returns(@stat).at_least_once
    @stat.expects(:total).returns(5).at_least_once
  end

  def set_roll_count
    @shooter = mock('shooter')
    @dice = mock('dice')
    @shooter.expects(:dice).returns(@dice).at_least_once
    @dice.expects(:num_rolls).returns(5).at_least_once
    @table.expects(:shooter).returns(@shooter).at_least_once
  end

  def set_config
    @config = mock('config')
    @table.expects(:config).returns(@config).at_least_once
  end

end
