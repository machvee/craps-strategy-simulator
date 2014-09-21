require 'test_helper'

class AcesBetTest < ActiveSupport::TestCase
  def setup
    @bet = mock_bet_setup(AcesBet)
  end

  def test_base_attrs
    assert_equal 'Aces Bet', @bet.name
    assert_equal CrapsBet::OnStatus::ON, @bet.table_on_status
  end

  def test_outcome_win_prop_met
    @dice = mock_dice
    @dice.expects(:rolled?).with(2).returns(true)
    assert_outcome_won(@bet)
  end

  def test_outcome_lose_prop_not_met
    @dice = mock_dice
    @dice.expects(:rolled?).with(2).returns(false)
    assert_outcome_lost(@bet)
  end

end
