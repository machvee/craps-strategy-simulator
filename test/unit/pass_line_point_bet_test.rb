require 'test_helper'

class PassLinePointBetTest < ActiveSupport::TestCase
  def setup
    number = 6
    @bet = mock_bet_setup(PassLinePointBet, number)
    @bet_amount = 10
  end

  def test_base_attrs
    assert_equal "Pass Line Bet #@number", @bet.name
    assert !@bet.player_can_set_off?
  end

  def test_validate_all_succeed
    player_bet = mock('player_bet')
    make_bet_base_validations_pass(player_bet, @bet_amount, @number)
    assert_nothing_raised do
      @bet.validate(player_bet, @bet_amount)
    end
  end

  def test_outcome_win_point_made
    mock_state(point_made?: true)
    assert_outcome_won(@bet)
  end

  def test_outcome_lose_seven_out
    mock_state(point_made?: false, seven_out?: true)
    assert_outcome_lost(@bet)
  end

  def test_outcome_no_outcome
    mock_state(point_made?: false, seven_out?: false)
    assert_outcome_none(@bet)
  end
end
