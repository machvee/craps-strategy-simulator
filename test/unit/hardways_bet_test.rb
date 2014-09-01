require 'test_helper'

class HardwaysBetTest < Test::Unit::TestCase
  def setup
    @number = 6
    @table = mock('table')
    @bet_stats = mock_bet_stats
    @table.expects(:bet_stats).at_least_once.returns(@bet_stats)
    @bet = HardwaysBet.new(@table, @number)
  end

  def test_base_attrs
    assert_equal 'Hardways Bet 6', @bet.name
    assert_equal CrapsBet::OnStatus::FOLLOW, @bet.table_on_status
  end

  def test_outcome_none_player_bet_off
    player_bet = mock('player_bet', off?: true)
    assert_equal CrapsBet::Outcome::NONE, @bet.determine_outcome(player_bet)
  end

  def test_outcome_lose_seven_player_bet_on
    player_bet = mock('player_bet', off?: false)
    @bet_stats.expects(:did_not_occur).with('hardways_bet_6s_won').once
    player_bet.expects(:stat_did_not_occur).with('hardways_bet_6s_won').once

    dice = mock('dice', seven?: true)
    @table.expects(:dice).returns(dice).at_least_once
    assert_equal CrapsBet::Outcome::LOSE, @bet.determine_outcome(player_bet)
  end

  def test_outcome_win_hard_player_bet_on
    player_bet = mock('player_bet', off?: false)
    @bet_stats.expects(:occurred).with('hardways_bet_6s_won').once
    player_bet.expects(:stat_occurred).with('hardways_bet_6s_won').once

    dice = mock('dice', hard?: true, seven?: false)
    @table.expects(:last_roll).returns(@number).at_least_once
    @table.expects(:dice).returns(dice).at_least_once
    assert_equal CrapsBet::Outcome::WIN, @bet.determine_outcome(player_bet)
  end

  def test_outcome_lose_easy_player_bet_on
    player_bet = mock('player_bet', off?: false)
    @bet_stats.expects(:did_not_occur).with('hardways_bet_6s_won').once
    player_bet.expects(:stat_did_not_occur).with('hardways_bet_6s_won').once

    dice = mock('dice', hard?: false, seven?: false)
    @table.expects(:last_roll).returns(@number).at_least_once
    @table.expects(:dice).returns(dice).at_least_once
    assert_equal CrapsBet::Outcome::LOSE, @bet.determine_outcome(player_bet)
  end

  def test_gen_number_bets
    HardwaysBet.expects(:new).with(@table, 4).once
    HardwaysBet.expects(:new).with(@table, 6).once
    HardwaysBet.expects(:new).with(@table, 8).once
    HardwaysBet.expects(:new).with(@table, 10).once
    HardwaysBet.gen_number_bets(@table)
  end

  def mock_bet_stats
    bet_stats = mock('bet_stats')
    bet_stats.expects(:add).at_least_once
    bet_stats
  end
end
