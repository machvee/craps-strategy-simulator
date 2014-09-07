require 'test_helper'

class AnySevenBetTest < ActiveSupport::TestCase
  def setup
    @bet = mock_bet_setup(AnySevenBet)
  end

  def test_base_attrs
    assert_equal 'Any Seven Bet', @bet.name
    assert_equal TableBet::OnStatus::ON, @bet.table_on_status
  end

  def test_outcome_win_prop_met
    mock_dice(seven?: true)
    assert_outcome_won(@bet)
  end

  def test_outcome_lose_prop_not_met
    mock_dice(seven?: false)
    assert_outcome_lost(@bet)
  end

end
