require 'test_helper'

class AceDeuceBetTest < ActiveSupport::TestCase
  def setup
    @bet = mock_bet_setup(AceDeuceBet)
  end

  def test_base_attrs
    assert_equal 'Ace Deuce Bet', @bet.name
    assert_equal CrapsBet::OnStatus::ON, @bet.table_on_status
  end

  def test_outcome_win_prop_met
    @dice = mock_dice
    @dice.expects(:rolled?).with(3).returns(true)
    assert_outcome_won(@bet)
  end

  def test_outcome_lose_prop_not_met
    @dice = mock_dice
    @dice.expects(:rolled?).with(3).returns(false)
    assert_outcome_lost(@bet)
  end

end
