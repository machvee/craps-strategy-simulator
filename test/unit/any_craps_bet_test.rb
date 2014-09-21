require 'test_helper'

class AnyCrapsBetTest < ActiveSupport::TestCase
  def setup
    @bet = mock_bet_setup(AnyCrapsBet)
  end

  def test_base_attrs
    assert_equal 'Any Craps Bet', @bet.name
    assert_equal CrapsBet::OnStatus::ON, @bet.table_on_status
  end

  def test_outcome_win_prop_met
    mock_dice(craps?: true)
    assert_outcome_won(@bet)
  end

  def test_outcome_lose_prop_not_met
    mock_dice(craps?: false)
    assert_outcome_lost(@bet)
  end

end
