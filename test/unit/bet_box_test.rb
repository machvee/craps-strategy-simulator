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
    PlayerBet.expects(:new).once.with(player, @bet_box, @amount).
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

    @bet_stat.expects(:won).once
    @player_bet.expects(:on?).once.returns(true)
    @player_bet.expects(:pay_winning_bet).once.with(*@payoff).returns(10000)
    @player_bet.expects(:remove).at_least_once.returns(false)
    @bet_box.expects(:mark_bet_deleted).once

    @bet_box.settle_player_bets do |player_bet, outcome, amount|
      assert_equal @player_bet, player_bet
      assert_equal CrapsBet::Outcome::WIN, outcome
      assert_equal amount, 10000
    end
  end

  def test_settle_player_bets_lose
    setup_bet_outcome(CrapsBet::Outcome::LOSE)
    @player_bet.expects(:remove=).once.with(true)

    @bet_stat.expects(:lost).once
    @player_bet.expects(:on?).once.returns(true)
    @player_bet.expects(:losing_bet).once
    @player_bet.expects(:amount).returns(@amount).at_least_once
    @player_bet.expects(:player).returns(@player).at_least_once
    @player_bet.expects(:remove).at_least_once.returns(true)
    @player.expects(:remove_from_player_bets).with(@player_bet).once

    @bet_box.settle_player_bets do |player_bet, outcome, amount|
      assert_equal @player_bet, player_bet
      assert_equal CrapsBet::Outcome::LOSE, outcome
      assert_equal amount, @amount
    end
  end

  def test_settle_player_bets_return
    setup_bet_outcome(CrapsBet::Outcome::RETURN)
    @player_bet.expects(:remove=).once.with(true)
    @player_bet.expects(:amount).returns(@amount).at_least_once
    @player_bet.expects(:player).returns(@player).at_least_once
    @player_bet.expects(:remove).at_least_once.returns(true)
    @player.expects(:remove_from_player_bets).with(@player_bet).once

    @player_bet.expects(:return_bet).once

    @bet_box.settle_player_bets do |player_bet, outcome, amount|
      assert_equal @player_bet, player_bet
      assert_equal CrapsBet::Outcome::RETURN, outcome
      assert_equal amount, @amount
    end
  end

  def test_settle_player_bets_morph
    setup_bet_outcome(CrapsBet::Outcome::MORPH)
    @craps_bet.morphs_to('down_under')
    @player_bet.expects(:player).returns(@player).at_least_once
    @player.expects(:remove_from_player_bets).with(@player_bet).once
    @player.expects(:bets).once.returns([@player_bet])
    @player_bet.expects(:remove).at_least_once.returns(true)
    @player_bet.expects(:remove=).once.with(true)
    @player_bet.expects(:craps_bet).once.returns(@craps_bet)
    @player_bet.expects(:amount).returns(@amount).at_least_once
    @last_roll = 4
    @table.expects(:last_roll).once.returns(@last_roll)
    @new_bet_box = mock('new_bet_box')
    @new_player_bet = mock('new player bet')
    @new_bet_box.expects(:new_player_bet).with(@player, @amount).returns(@new_player_bet)
    @table.expects(:find_bet_box).with('down_under', @last_roll).returns(@new_bet_box)

    @bet_box.settle_player_bets do |player_bet, outcome, amount|
      raise "MORPH should not yield"
    end
  end

  def setup_bet_outcome(outcome)
    @craps_bet.expects(:outcome).once.returns(outcome)
    @amount = 10
    @bet_box = BetBox.new(@table, @craps_bet)
    @player = mock('player')
    @player_bet = mock('player_bet')
    PlayerBet.expects(:new).once.with(@player, @bet_box, @amount).once.returns(@player_bet)
    assert @bet_box.new_player_bet(@player, @amount)
    player_bets = [@player_bet]
    @bet_box.expects(:player_bets).at_least_once.returns(player_bets)
  end

  def setup_cool(number, payoff_odds)

    @number = number

    @bet_stat         = mock('bet_stat')
    @player_bet_stats = mock('player_bet_stats')
    @dice_bet_stats   = mock('dice_bet_stats')
    @table_config     = mock('table_config')


    @table = mock('table', player_bet_stats: @player_bet_stats,
                           dice_bet_stats: @dice_bet_stats)
    @table.expects(:config).at_least_once.returns(@table_config)
    @table_config.expects(:payoff_odds).at_least_once.returns(payoff_odds)


    bet = CoolBet.new(@table, @number)
    bet.expects(:create_bet_stat).at_least_once.returns(@bet_stat)

    @player_bet_stats.expects(:add).once.with(@bet_stat)
    @dice_bet_stats.expects(:add).once.with(@bet_stat)

    bet

  end

end
