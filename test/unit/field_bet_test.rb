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
    (CrapsDice::FIELDS - [2,12]).each do |num|
      @dice = mock_dice(fields?: true)
      @dice.expects(:rolled?).once.with(2).returns(false)
      @dice.expects(:rolled?).once.with(12).returns(false)
      assert_outcome_won(@bet)
    end
  end

  def test_outcome_win_field_made_special_2_stat
    @dice = mock_dice(fields?: true)
    @dice.expects(:rolled?).once.with(2).returns(true)
    assert_outcome_won(@bet, {FieldBet::STAT_NAME_HASH[2] => OccurrenceStat::OCCURRED})
  end

  def test_outcome_win_field_made_special_12_stat
    @dice = mock_dice(fields?: true)
    @dice.expects(:rolled?).once.with(2).returns(false)
    @dice.expects(:rolled?).once.with(12).returns(true)
    assert_outcome_won(@bet, {FieldBet::STAT_NAME_HASH[12] => OccurrenceStat::OCCURRED})
  end

  def test_outcome_lose_no_field
    ([*2..12] - CrapsDice::FIELDS).each do |num|
      @dice = mock_dice(fields?: false)
      assert_outcome_lost(@bet)
    end
  end

end
