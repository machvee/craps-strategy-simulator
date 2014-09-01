require 'test_helper'

class PassLineBetTest < Test::Unit::TestCase
  def setup
    @table = mock('table')
    @bet_stats = mock_bet_stats
    @table.expects(:bet_stats).at_least_once.returns(@bet_stats)
    @bet = PassLineBet.new(@table)
  end

  def test_base_attrs
    assert_equal 'Pass Line Bet', @bet.name
    assert !@bet.player_can_set_off?
  end

  def test_validate_all_succeed
    table_state = mock('table_state', on?: false)
    @table.expects(:state).returns(table_state).at_least_once
    player_bet = mock('player_bet')
    make_base_validations_pass(player_bet)
    assert_nothing_raised do
      @bet.validate(player_bet, 10)
    end
  end

  def test_validate_fail_table_off
    @table.expects(:state).returns(table_state).at_least_once
    table_state = mock('table_state', on?: true)
    player_bet = mock('player_bet')
    make_base_validations_pass(player_bet)
    assert_raises RuntimeError do
      @bet.validate(player_bet, 10)
    end
  end

  def test_outcome_win_seven
    table_state = mock('table_state', front_line_winner?: true)
    @table.expects(:state).returns(table_state).at_least_once
    player_bet = mock('player_bet')
    stat_occurred(player_bet, 'pass_line_bets_won')
    stat_occurred(player_bet, PassLineBet::FRONT_LINE_WINNER_STAT_NAME)

    assert_equal CrapsBet::Outcome::WIN, @bet.determine_outcome(player_bet)
  end

  def test_outcome_lose_crapped_out
    table_state = mock('table_state', front_line_winner?: false, crapped_out?: true)
    @table.expects(:state).returns(table_state).at_least_once
    player_bet = mock('player_bet')
    stat_occurred(player_bet, 'pass_line_bets_won', false)
    stat_occurred(player_bet, PassLineBet::FRONT_LINE_WINNER_STAT_NAME, false)

    assert_equal CrapsBet::Outcome::LOSE, @bet.determine_outcome(player_bet)
  end

  def test_outcome_win_point_made
    table_state = mock('table_state',
      front_line_winner?: false, crapped_out?: false, point_made?: true)
    @table.expects(:state).returns(table_state).at_least_once
    player_bet = mock('player_bet')
    stat_occurred(player_bet, 'pass_line_bets_won')
    stat_occurred(player_bet, PassLineBet::POINT_MADE_STAT_NAME)

    assert_equal CrapsBet::Outcome::WIN, @bet.determine_outcome(player_bet)
  end

  def test_outcome_lose_seven_out
    table_state = mock('table_state',
      front_line_winner?: false, crapped_out?: false, point_made?: false, seven_out?: true)
    @table.expects(:state).returns(table_state).at_least_once
    player_bet = mock('player_bet')
    stat_occurred(player_bet, 'pass_line_bets_won', false)
    stat_occurred(player_bet, PassLineBet::POINT_MADE_STAT_NAME, false)

    assert_equal CrapsBet::Outcome::LOSE, @bet.determine_outcome(player_bet)
  end

  def test_outcome_no_outcome
    table_state = mock('table_state',
      front_line_winner?: false, crapped_out?: false, point_made?: false, seven_out?: false)
    @table.expects(:state).returns(table_state).at_least_once
    player_bet = mock('player_bet')

    assert_equal CrapsBet::Outcome::NONE, @bet.determine_outcome(player_bet)
  end

  def mock_bet_stats
    bet_stats = mock('bet_stats')
    bet_stats.expects(:add).times(4)
    bet_stats
  end

  def stat_occurred(player_bet, stat_name, occurred=true)
    methods = {true => [:occurred, :stat_occurred],
               false => [:did_not_occur, :stat_did_not_occur]}
    @bet_stats.expects(methods[occurred].first).with(stat_name).once
    player_bet.expects(methods[occurred].last).with(stat_name).once
  end

  def make_base_validations_pass(player_bet)
    player = mock('player')
    player.expects(:has_bet?).with(PassLineBet, nil).returns(false).once
    player_bet.expects(:player).at_least_once.returns(player)

    bet_amount = 10
    @table.expects(:min_bet).returns(bet_amount).at_least_once
    @table.expects(:max_bet).returns(bet_amount+1).at_least_once

    @table_config = mock('table_config')
    @table_config.expects(:payoff_odds).at_least_once.with(@bet, @number).returns([1,1])
    @table.expects(:config).at_least_once.returns(@table_config)
  end

end
