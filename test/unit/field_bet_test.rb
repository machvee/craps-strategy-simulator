require 'test_helper'

class FieldBetTest < ActiveSupport::TestCase
  def setup
    @bet = mock_bet_setup(FieldBet)
  end

  def test_base_attrs
    assert_equal 'Field Bet', @bet.name
    assert @bet.player_can_set_off?
  end

  def test_outcome_win_field_made
    CrapsDice::FIELDS.each do |num|
      @dice = mock_dice(fields?: true)
      assert_outcome_won(@bet)
    end
  end

  def test_outcome_lose_no_field
    ([*2..12] - CrapsDice::FIELDS).each do |num|
      @dice = mock_dice(fields?: false)
      assert_outcome_lost(@bet)
    end
  end

end
