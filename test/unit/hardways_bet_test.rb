require 'test_helper'

class HardwaysBetTest < ActiveSupport::TestCase
  def setup
    @number = 6
    @bet = mock_bet_setup(HardwaysBet, @number)
  end

  def test_base_attrs
    assert_equal 'Hardways Bet 6', @bet.name
    assert_equal TableBet::OnStatus::FOLLOW, @bet.table_on_status
  end

  def test_outcome_none
    dice = mock_dice(seven?: false)
    dice.expects(:rolled?).with(@number).returns(false)
    assert_outcome_none(@bet)
  end

  def test_outcome_lose_seven
    @dice = mock_dice(seven?: true)
    assert_outcome_lost(@bet)
  end

  def test_outcome_win_hard
    dice = mock_dice(hard?: true, seven?: false)
    dice.expects(:rolled?).with(@number).returns(true)
    assert_outcome_won(@bet)
  end

  def test_outcome_lose_easy
    dice = mock_dice(hard?: false, seven?: false)
    dice.expects(:rolled?).with(@number).returns(true)
    assert_outcome_lost(@bet)
  end

  def test_gen_number_bets
    CrapsDice::HARDS.each do |v|
       HardwaysBet.expects(:new).with(@table, v).once
    end
    HardwaysBet.gen_number_bets(@table)
  end
end
