require 'test_helper'

class PassLineBetTest < ActiveSupport::TestCase
  def setup
    @number = 6
    @bet = mock_bet_setup(PassLineBet)
    @bet_amount = 10
  end

  def test_base_attrs
    assert_equal 'Pass Line Bet', @bet.name
    assert !@bet.player_can_set_off?
  end

  def test_validate_all_succeed
    mock_state(on?: false)
    player_bet = mock('player_bet')
    make_bet_base_validations_pass(player_bet, @bet_amount)
    assert_nothing_raised do
      @bet.validate(player_bet, @bet_amount)
    end
  end

  def test_validate_fail_table_off
    mock_state(on?: true)
    player_bet = mock('player_bet')
    make_bet_base_validations_pass(player_bet, @bet_amount)
    assert_raises RuntimeError do
      @bet.validate(player_bet, @bet_amount)
    end
  end

  def test_outcome_win_seven
    mock_state(front_line_winner?: true)
    assert_outcome_won(@bet)
  end

  def test_outcome_lose_crapped_out
    mock_state(front_line_winner?: false, crapped_out?: true)
    assert_outcome_lost(@bet)
  end

  def test_outcome_morph_outcome
    @dice = mock_dice
    @dice.expects(:points?).returns(true)
    mock_state(front_line_winner?: false, crapped_out?: false)
    assert_outcome_morph(@bet)
    assert_equal 'pass_line_point', @bet.morph_bet_name
  end
end
