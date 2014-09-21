require 'test_helper'

class TwelveTest < ActiveSupport::TestCase
  def setup
    @bet = mock_bet_setup(TwelveBet)
  end

  def test_base_attrs
    assert_equal 'Twelve Bet', @bet.name
    assert_equal CrapsBet::OnStatus::ON, @bet.table_on_status
  end

  def test_outcome_win_prop_met
    @dice = mock_dice
    @dice.expects(:rolled?).with(12).returns(true)
    assert_outcome_won(@bet)
  end

  def test_outcome_lose_prop_not_met
    @dice = mock_dice
    @dice.expects(:rolled?).with(12).returns(false)
    assert_outcome_lost(@bet)
  end

end
