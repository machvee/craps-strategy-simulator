require 'test_helper'

class RunStopperTest < ActiveSupport::TestCase

  def setup
    @player = mock('player')
    @table = mock('table')
    @player.stubs(:table).returns(@table)
  end

  def test_down_percent_option_parse
    dp = 20
    rs(down_percent: dp)
    assert_equal -dp, @run_stopper.down_percent
  end

  def test_up_percent_option_parse
    up = 38
    rs(up_percent: up)
    assert_equal up, @run_stopper.up_percent
  end

  def test_both_up_down_parse_rest_nil
    dp = 18; up = 48
    rs(up_percent: up, down_percent: dp)
    assert_equal up, @run_stopper.up_percent
    assert_equal -dp, @run_stopper.down_percent
    assert @run_stopper.down_amount.nil?, "down_amount should be nil"
    assert @run_stopper.up_amount.nil?, "down_amount should be nil"
    assert @run_stopper.shooters.nil?, "shooters should be nil"
    assert @run_stopper.points.nil?, "points should be nil"
  end

  def test_down_amount_parse
    da = 1850
    rs(down_amount: da)
    assert_equal -da, @run_stopper.down_amount
  end

  def test_up_amount_parse
    ua = 411
    rs(up_amount: ua)
    assert_equal ua, @run_stopper.up_amount
  end

  def test_shooters_parse
    sh = 189
    pass_line_point_stat(0, 0)
    rs(shooters: sh)
    assert_equal sh, @run_stopper.shooters
  end

  def test_points_parse
    p = 3217
    pass_line_point_stat(9, 43)
    rs(points: p)
    assert_equal p, @run_stopper.points
  end

  def test_all_options_parse
    dp = 98; up = 16; sh = 391; p = 1135; ua = 500; da = 630
    pass_line_point_stat(88, 93)
    rs(
      up_percent: up,
      down_percent: dp,
      up_amount: ua,
      down_amount: da,
      shooters: sh,
      points: p
    )
    assert_equal up, @run_stopper.up_percent
    assert_equal -dp, @run_stopper.down_percent
    assert_equal ua, @run_stopper.up_amount
    assert_equal -da, @run_stopper.down_amount
    assert_equal p, @run_stopper.points
    assert_equal sh, @run_stopper.shooters
  end

  def test_up_percent_stop
    up = 20
    rs(up_percent: up)
    no_stop_with_rail(1000, 1000)
    no_stop_with_rail(1000, 1100)
    stop_with_rail(1000, 1200)
    stop_with_rail(1000, 1400)
    no_stop_with_rail(1000, 400)
  end

  def test_down_percent_stop
    dp = 30
    rs(down_percent: dp)
    no_stop_with_rail(1000, 1000) # equal
    no_stop_with_rail(1000, 900) # not down enough
    no_stop_with_rail(1000, 800) # not down enough
    no_stop_with_rail(1000, 1400) # up
    no_stop_with_rail(1000, 701) # not quite down 30%
    stop_with_rail(1000, 700) # down 30%
    stop_with_rail(1000, 699) # down >30%
    stop_with_rail(1000, 0) # bust
  end

  def test_combined_percent_stop
    up = 200; down = 50
    rs(up_percent: up, down_percent: down)
    no_stop_with_rail(1000, 1000)
    no_stop_with_rail(1000, 2000)
    stop_with_rail(1000, 3000)
    stop_with_rail(1000, 4000)
    no_stop_with_rail(1000, 900)
    no_stop_with_rail(1000, 501)
    stop_with_rail(1000, 500)
    stop_with_rail(1000, 499)
    stop_with_rail(1000, 0)
  end

  def test_up_amount_stop
    ua = 200
    rs(up_amount: ua)
    no_stop_with_rail(1000, 1000)
    no_stop_with_rail(1000, 1100)
    no_stop_with_rail(1000, 1199)
    stop_with_rail(1000, 1200)
    stop_with_rail(1000, 1400)
    no_stop_with_rail(1000, 400)
  end

  def test_down_amount_stop
    da = 500
    rs(down_amount: da)
    no_stop_with_rail(1000, 1000) # equal
    no_stop_with_rail(1000, 900) # not down enough
    no_stop_with_rail(1000, 800) # not down enough
    no_stop_with_rail(1000, 1400) # up
    no_stop_with_rail(1000, 1000-da+1) # not quite down 500
    stop_with_rail(1000, 1000-da)
    stop_with_rail(1000, 1000-da-1) # down >30%
    stop_with_rail(1000, 0) # bust
  end

  def test_shooter_turns_stop
    sh = 18
    pass_line_point_stat(0, 0)
    rs(shooters: sh)
    no_stop_with_stat(0, 0)
    no_stop_with_stat(0, 17)
    stop_with_stat(0, 18)
  end

  def test_points_stop
    p = 3217
    pass_line_point_stat(9, 43)
    rs(points: p)
    no_stop_with_stat(9, 43)
    no_stop_with_stat(9+p-1, 43)
    stop_with_stat(9+p, 43)
  end

  def test_multi_criteria_stop
    pass_line_point_stat(0, 0)
    player_rail(start_balance: 1000, balance: 1000)
    rs(
      up_percent: 100,
      down_percent: 50,
      shooters: 10,
      points: 60
    )
    no_stop_with_stat(0,0)
    no_stop_with_stat(59,9)
    stop_with_stat(0,10)
    stop_with_stat(60,9)
    pass_line_point_stat(59, 9)
    no_stop_with_rail(1000,1000)
    stop_with_rail(1000,2000)
    no_stop_with_rail(1000,501)
    stop_with_rail(1000,499)
  end

  private

  def stop_with_rail(sb, b)
    player_rail(start_balance: sb, balance: b)
    assert @run_stopper.stop?, "should have stopped with start_balance: #{sb}, balance: #{b}"
  end

  def no_stop_with_rail(sb, b)
    player_rail(start_balance: sb, balance: b)
    assert !@run_stopper.stop?, "should not have stopped with start_balance: #{sb}, balance: #{b}"
  end

  def stop_with_stat(count, total_lost)
    pass_line_point_stat(count, total_lost)
    assert @run_stopper.stop?, "should have stopped with count: #{count}, total_lost: #{total_lost}"
  end

  def no_stop_with_stat(count, total_lost)
    pass_line_point_stat(count, total_lost)
    assert !@run_stopper.stop?, "should not have stopped with count: #{count}, total_lost: #{total_lost}"
  end

  def pass_line_point_stat(count, total_lost)
    @table.stubs(:tracking_bet_stats).returns(stub(pass_line_point: stub(total_lost: total_lost, count: count)))
  end

  def player_rail(balance_hash)
    @player.stubs(:rail).returns(stub(balance_hash))
  end

  def rs(opts)
    @run_stopper = RunStopper.new(@player, @options=opts)
  end

end
