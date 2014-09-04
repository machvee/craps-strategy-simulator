require 'test_helper'

class PassOddsBetTest < Test::Unit::TestCase
  def setup
    @table = mock('table')
    @number = 6
    @stat_name = 'pass_odds_%d'%@number
    @bet_stats = mock_bet_stats
    @table.expects(:bet_stats).at_least_once.returns(@bet_stats)
    @bet = PassOddsBet.new(@table, @number)
  end

  def test_base_attrs
    assert_equal 'Pass Line Odds Bet %d' % @number, @bet.name
    assert @bet.player_can_set_off?
  end

  def test_validate_all_succeed
    table_state = mock('table_state', on?: true)
    @table.expects(:table_state).returns(table_state).at_least_once
    player_bet = mock('player_bet')
    player = mock('player')
    make_base_validations_pass(player_bet, player)
    player.expects(:has_bet?).with(PassLineBet, nil).returns(true).once
    assert_nothing_raised do
      @bet.validate(player_bet, 10)
    end
  end

  def test_validate_fail_table_off
    table_state = mock('table_state', on?: false)
    @table.expects(:table_state).returns(table_state).at_least_once
    player_bet = mock('player_bet')
    player = mock('player')
    make_base_validations_pass(player_bet, player)
    assert_raises RuntimeError do
      @bet.validate(player_bet, 50)
    end
  end

  def test_validate_fail_no_pass_line_bet
    table_state = mock('table_state', on?: true)
    @table.expects(:table_state).returns(table_state).at_least_once
    player_bet = mock('player_bet')
    player = mock('player')
    make_base_validations_pass(player_bet, player)
    player.expects(:has_bet?).with(PassLineBet, nil).returns(false).once
    assert_raises RuntimeError do
      @bet.validate(player_bet, 50)
    end
  end

  def test_outcome_win_point_made
    table_state = mock('table_state', point_made?: true)
    @table.expects(:table_state).returns(table_state).at_least_once
    player_bet = mock('player_bet')
    player_bet.expects(:off?).once.returns(false)
    stat_occurred(player_bet, @stat_name)

    assert_equal TableBet::Outcome::WIN, @bet.determine_outcome(player_bet)
  end

  def test_outcome_lose_seven_out
    table_state = mock('table_state', point_made?: false, seven_out?: true)
    @table.expects(:table_state).returns(table_state).at_least_once
    player_bet = mock('player_bet')
    player_bet.expects(:off?).once.returns(false)
    stat_occurred(player_bet, @stat_name, false)

    assert_equal TableBet::Outcome::LOSE, @bet.determine_outcome(player_bet)
  end

  def test_outcome_no_outcome
    table_state = mock('table_state', point_made?: false, seven_out?: false)
    @table.expects(:table_state).returns(table_state).at_least_once
    player_bet = mock('player_bet')
    player_bet.expects(:off?).once.returns(false)

    assert_equal TableBet::Outcome::NONE, @bet.determine_outcome(player_bet)
  end

  def test_outcome_bet_off_no_outcome
    player_bet = mock('player_bet')
    player_bet.expects(:off?).once.returns(true)

    assert_equal TableBet::Outcome::NONE, @bet.determine_outcome(player_bet)
  end

  def mock_bet_stats
    bet_stats = mock('bet_stats')
    bet_stats.expects(:add).at_least_once
    bet_stats
  end

  def stat_occurred(player_bet, stat_name, occurred=true)
    methods = {true => [:occurred, :stat_occurred],
               false => [:did_not_occur, :stat_did_not_occur]}
    @bet_stats.expects(methods[occurred].first).with(stat_name).once
    player_bet.expects(methods[occurred].last).with(stat_name).once
  end

  def make_base_validations_pass(player_bet, player)
    player.expects(:has_bet?).with(PassOddsBet, @number).returns(false).once
    player_bet.expects(:player).at_least_once.returns(player)

    bet_amount = 10
    @bet.expects(:min_bet).returns(bet_amount).at_least_once
    @bet.expects(:max_bet).returns(bet_amount*100).at_least_once

    @table_config = mock('table_config')
    @table_config.expects(:payoff_odds).at_least_once.with(@bet, @number).returns([6,5])
    @table.expects(:config).at_least_once.returns(@table_config)
  end

end