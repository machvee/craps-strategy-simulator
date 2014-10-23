require 'test_helper'

class BetBoxTest < ActiveSupport::TestCase
  class CoolBet < CrapsBet
    def name
      "Cool Bet on #{number}"
    end
  end

  def setup
    @payoff = [3,1]
    @craps_bet = setup_cool(6, @payoff)
  end

  def test_instantiate
    @bet_box = BetBox.new(@table, @craps_bet)
    assert @bet_box
  end

  def test_short_name
    @bet_box = BetBox.new(@table, @craps_bet)
    assert_equal 'bet_box_test/cool', @bet_box.short_name
  end

  def test_new_player_bet
    @amount = 10
    @bet_box = BetBox.new(@table, @craps_bet)
    player = mock('player')
    player.expects(:new_bet).once.with(@bet_box, @amount).
      once.returns(mock('player_bet'))
    pb = @bet_box.new_player_bet(player, @amount)
    assert_equal 1, @bet_box.player_bets.length
    assert_equal pb, @bet_box.player_bets.first
  end

  def test_remove_bet
    player_bet = mock('player_bet')
    player = mock('player')
    player_bet.expects(:remove).at_least_once.returns(true)
    player_bet.expects(:remove=).once.with(true)
    player_bets = [player_bet]
    player_bet.expects(:player).returns(player).at_least_once
    player.expects(:remove_from_player_bets).with(player_bet).once
    @bet_box = BetBox.new(@table, @craps_bet)
    @bet_box.expects(:player_bets).at_least_once.returns(player_bets)

    @bet_box.remove_bet(player_bet)
    assert_equal 0, player_bets.length
  end

  def test_settle_player_bets_win
    setup_bet_outcome(CrapsBet::Outcome::WIN)

    @player_bet.expects(:on?).once.returns(true)
    @player_bet.expects(:winning_bet).once.with(*@payoff).returns(10000)
    @player_bet.expects(:remove).at_least_once.returns(false)
    @bet_box.expects(:mark_bet_deleted).once

    @bet_box.settle_player_bets 
  end

  def test_settle_player_bets_lose
    setup_bet_outcome(CrapsBet::Outcome::LOSE)
    @player_bet.expects(:remove=).once.with(true)

    @player_bet.expects(:on?).once.returns(true)
    @player_bet.expects(:losing_bet).once
    @player_bet.expects(:player).returns(@player).at_least_once
    @player_bet.expects(:remove).at_least_once.returns(true)
    @player.expects(:remove_from_player_bets).with(@player_bet).once

    @bet_box.settle_player_bets 
  end

  def test_settle_player_bets_return
    setup_bet_outcome(CrapsBet::Outcome::RETURN)
    @player_bet.expects(:remove=).once.with(true)
    @player_bet.expects(:remove).at_least_once.returns(true)
    @player_bet.expects(:player).returns(@player).at_least_once
    @player.expects(:remove_from_player_bets).with(@player_bet).once

    @player_bet.expects(:return_bet).once

    @bet_box.settle_player_bets 
  end

  def test_settle_player_bets_morph
    setup_bet_outcome(CrapsBet::Outcome::MORPH)
    @player_bet.expects(:player).returns(@player).at_least_once
    @player.expects(:remove_from_player_bets).with(@player_bet).once
    @player_bet.expects(:remove).at_least_once.returns(true)
    @player_bet.expects(:return_wager).at_least_once
    @player_bet.expects(:remove=).once.with(true)
    @table.expects(:morph_bets).once.returns([])

    @bet_box.settle_player_bets 
  end

  def setup_bet_outcome(outcome)
    @craps_bet.expects(:outcome).once.returns(outcome)
    @amount = 10
    @bet_box = BetBox.new(@table, @craps_bet)
    @player = mock('player')
    @player_bet = mock('player_bet')
    @player.expects(:new_bet).once.with(@bet_box, @amount).once.returns(@player_bet)
    assert @bet_box.new_player_bet(@player, @amount)
    player_bets = [@player_bet]
    @bet_box.expects(:player_bets).at_least_once.returns(player_bets)
  end

  def setup_cool(number, payoff_odds)

    @number = number

    @player_bet_stats = mock('player_bet_stats')
    @tracking_bet_stats   = mock('tracking_bet_stats')
    @table_config     = mock('table_config')


    @table = mock('table', player_bet_stats: @player_bet_stats,
                           tracking_bet_stats: @tracking_bet_stats)
    @table.expects(:config).at_least_once.returns(@table_config)
    @table_config.expects(:payoff_odds).at_least_once.returns(payoff_odds)


    bet = CoolBet.new(@table, @number)
    bet.expects(:create_bet_stat).at_least_once.returns(@bet_stat)

    @player_bet_stats.expects(:add).once.with(@bet_stat)
    @tracking_bet_stats.expects(:add).once.with(@bet_stat)

    bet

  end

end
