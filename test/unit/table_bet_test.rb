require 'test_helper'

class TableBetTest < Test::Unit::TestCase
  class CoolBet < TableBet
    def name
      "Cool Bet on #{number}"
    end

    def outcome(player_bet)
      result = if table.win?
        Outcome::WIN
      elsif table.lose?
        Outcome::LOSE
      else
        Outcome::NONE
      end
    end
  end

  def setup
    @number = 2
    @table_config = mock('table_config')
    @table = mock('table')
    @state = mock('table_state')
    @bet_stats = mock('bet_stats')
    @bet_stats.expects(:add).at_least_once
    @table.expects(:bet_stats).at_least_once.returns(@bet_stats)
    @cool_bet = CoolBet.new(@table, @number)
    @won_stat_name = 'table_test/cool_2'
  end

  def test_cool_bet
    assert_equal "Cool Bet on #@number", @cool_bet.name
    assert_equal @number, @cool_bet.number
    assert @cool_bet.on?, "default should be always on"
    assert @cool_bet.bet_remains_after_win?, "default expected that bet remains on table after win"
    assert @cool_bet.player_can_set_off?, "default expected that player can mark bet off"
  end

  def test_bet_follow_table
    @cool_bet.expects(:table_on_status).twice.returns(TableBet::OnStatus::FOLLOW)
    @table.expects(:table_state).at_least_once.returns(@state)
    @state.expects(:on?).returns(false).once
    assert !@cool_bet.on?, "bet should be off because table is off"
    @state.expects(:on?).returns(true).once
    assert @cool_bet.on?, "bet should be on because table is on"
  end

  def test_bet_payout
    @table_config.expects(:payoff_odds).at_least_once.with(@cool_bet, @number).returns([20,1])
    @table.expects(:config).at_least_once.returns(@table_config)
    assert_equal [20,1], @cool_bet.payout
  end

  def test_made_the_number
    @table.expects(:last_roll).once.returns(@number)
    assert @cool_bet.made_the_number?, "table last_roll is #@number, should've made the number"
    not_number=@number+1
    @table.expects(:last_roll).once.returns(not_number)
    assert !@cool_bet.made_the_number?, "table last_roll is #{not_number}, shouldn't have made the number"
  end

  def test_add_player_bet
    assert @cool_bet.player_bets.length == 0
    player_bet = mock('player_bet')
    @cool_bet.add_bet(player_bet)
    assert @cool_bet.player_bets.first.present?
  end

  def test_remove_player_bet
    assert_equal 0, @cool_bet.player_bets.length
    player_bet = mock('player_bet')
    @cool_bet.add_bet(player_bet)
    assert @cool_bet.player_bets.first.present?
    @cool_bet.remove_bet(player_bet)
    assert_equal 0, @cool_bet.player_bets.length
  end

  def test_determine_outcome_with_player_bet_winning
    assert @cool_bet.player_bets.length == 0
    player_bet = mock('player_bet')
    @cool_bet.add_bet(player_bet)
    assert @cool_bet.player_bets.first.present?
    
    @table.expects(:win?).returns(true)
    @bet_stats.expects(:occurred).with(@won_stat_name).once
    player_bet.expects(:stat_occurred).with(@won_stat_name).once
    @cool_bet.determine_outcome(player_bet)
  end

  def test_determine_outcome_with_player_bet_losing
    assert @cool_bet.player_bets.length == 0
    player_bet = mock('player_bet')
    @cool_bet.add_bet(player_bet)
    assert @cool_bet.player_bets.first.present?
    
    @table.expects(:lose?).returns(true)
    @table.expects(:win?).returns(false)
    @bet_stats.expects(:did_not_occur).with(@won_stat_name).once
    player_bet.expects(:stat_did_not_occur).with(@won_stat_name).once
    @cool_bet.determine_outcome(player_bet)
  end

  def test_determine_outcome_with_player_bet_nothing_happened
    assert @cool_bet.player_bets.length == 0
    player_bet = mock('player_bet')
    @cool_bet.add_bet(player_bet)
    assert @cool_bet.player_bets.first.present?
    
    @table.expects(:lose?).returns(false)
    @table.expects(:win?).returns(false)
    @bet_stats.expects(:did_not_occur).never
    @bet_stats.expects(:occurred).never
    player_bet.expects(:stat_did_not_occur).never
    player_bet.expects(:stat_occurred).never
    @cool_bet.determine_outcome(player_bet)
  end

  def test_validate_player_already_has_that_bet
    player_bet = mock('player_bet')
    player = mock('player')
    player.expects(:has_bet?).with(TableBetTest::CoolBet, @number).returns(true).once
    player_bet.expects(:player).at_least_once.returns(player)

    bet_amount = 10
    assert_raise RuntimeError do
      @cool_bet.validate(player_bet, bet_amount)
    end
  end

  def test_validate_player_must_bet_min_bet
    player_bet = mock('player_bet')
    player = mock('player')
    player.expects(:has_bet?).with(TableBetTest::CoolBet, @number).returns(false).once
    player_bet.expects(:player).at_least_once.returns(player)

    bet_amount = 10
    @table.expects(:min_bet).returns(bet_amount + 1).at_least_once

    assert_raise RuntimeError do
      @cool_bet.validate(player_bet, bet_amount)
    end
  end

  def test_validate_player_must_bet_under_max_bet
    player_bet = mock('player_bet')
    player = mock('player')
    player.expects(:has_bet?).with(TableBetTest::CoolBet, @number).returns(false).once
    player_bet.expects(:player).at_least_once.returns(player)

    bet_amount = 10
    @table.expects(:min_bet).returns(bet_amount).at_least_once
    @table.expects(:max_bet).returns(bet_amount-1).at_least_once

    assert_raise RuntimeError do
      @cool_bet.validate(player_bet, bet_amount)
    end
  end

  def test_betting_multiple_not_a_multiple_of_for_every_payout
    player_bet = mock('player_bet')
    player = mock('player')
    player.expects(:has_bet?).with(TableBetTest::CoolBet, @number).returns(false).once
    player_bet.expects(:player).at_least_once.returns(player)

    bet_amount = 10
    @table.expects(:min_bet).returns(bet_amount).at_least_once
    @table.expects(:max_bet).returns(bet_amount+1).at_least_once

    @table_config.expects(:payoff_odds).at_least_once.with(@cool_bet, @number).returns([5,3])
    @table.expects(:config).at_least_once.returns(@table_config)

    assert_raise RuntimeError do
      @cool_bet.validate(player_bet, bet_amount)
    end
  end

  def test_all_validations_pass
    player_bet = mock('player_bet')
    player = mock('player')
    player.expects(:has_bet?).with(TableBetTest::CoolBet, @number).returns(false).once
    player_bet.expects(:player).at_least_once.returns(player)

    bet_amount = 10
    @table.expects(:min_bet).returns(bet_amount).at_least_once
    @table.expects(:max_bet).returns(bet_amount+1).at_least_once

    @table_config.expects(:payoff_odds).at_least_once.with(@cool_bet, @number).returns([7,2])
    @table.expects(:config).at_least_once.returns(@table_config)

    @cool_bet.validate(player_bet, bet_amount)

  end
end
