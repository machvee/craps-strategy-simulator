require 'test_helper'

class PlayerTest < ActiveSupport::TestCase
  def setup
    @table = mock('table')
    @amount = 1000
  end

  def test_instantiate_player
    new_player
    assert @player.present?
  end

  def test_join_table
    @table.expects(:new_player).with('dave', @amount).once
    Player.join_table(@table, 'dave', @amount)
  end

  def test_make_valid_bet
    new_player
    PlayerBet.expects(:new).once.returns(mock('player_bet'))
    pass_line_bet = mock('pass_line_bet')
    @table.expects(:find_table_bet).once.returns(pass_line_bet)
    start_r = @player.rail
    @player.make_bet(PassLineBet, 10, 2)
    assert_equal 10, @player.wagers
    assert_equal start_r - 10, @player.rail
  end

  def new_player
    bet_stats = mock('bet_stats')
    bet_stats.expects(:new_instance).once
    @table.expects(:bet_stats).returns(bet_stats)
    @player = Player.new('dave', @table, @amount)
  end

end
