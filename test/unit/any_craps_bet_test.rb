require 'test_helper'

class AnyCrapsBetTest < Test::Unit::TestCase
  def setup
    @table = mock('table')
    @bet_stats = mock_bet_stats
    @table.expects(:bet_stats).at_least_once.returns(@bet_stats)
    @bet = AnyCrapsBet.new(@table)
    @won_stat_name = 'any_craps'
  end

  def test_base_attrs
    assert_equal 'Any Craps Bet', @bet.name
    assert_equal TableBet::OnStatus::ON, @bet.table_on_status
  end

  def test_outcome_win_prop_met
    @bet_stats.expects(:occurred).with(@won_stat_name).once

    dice = mock('dice')
    dice.expects(:craps?).returns(true)
    @table.expects(:dice).returns(dice).at_least_once
    assert_equal TableBet::Outcome::WIN, @bet.determine_outcome
  end

  def test_outcome_lose_prop_not_met
    @bet_stats.expects(:did_not_occur).with(@won_stat_name).once

    dice = mock('dice')
    dice.expects(:craps?).returns(false)
    @table.expects(:dice).returns(dice).at_least_once
    assert_equal TableBet::Outcome::LOSE, @bet.determine_outcome
  end

  def mock_bet_stats
    bet_stats = mock('bet_stats')
    bet_stats.expects(:add).at_least_once
    bet_stats
  end
end
