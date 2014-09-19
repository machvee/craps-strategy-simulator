class BetBox
  attr_reader :table
  attr_reader :craps_bet
  attr_reader :dice_bet_stat   # keeps table stats on outcome of dice

  attr_reader :player_bets

  delegate :name, :number, to: craps_bet

  def initialize(table, craps_bet)
    @table = table
    @craps_bet = craps_bet
    @table.dice_bet_stats.add(@dice_bet_stat = craps_bet.bet_stat)
    @table.player_bet_stats.add(craps_bet.bet_stat)

    @player_bets = []
  end

  def short_name
    craps_bet.class.short_name
  end

  def new_player_bet(player, amount)
    PlayerBet.new(player, craps_bet, amount).tap do |pb|
      player_bets << pb
    end
  end

  def remove_bet(player_bet)
    mark_bet_deleted(player_bet)
    remove_marked_bets
  end

  def settle_player_bets(&block)
    outcome = craps_bet.outcome
    player_bets.each do |player_bet|
      case outcome
      when CrapsBet::WIN
        dice_bet_stat.won
        pay_winning(player_bet) if player_bet.on?

      when CrapsBet::LOSE
        dice_bet_stat.lost
        take_losing(player_bet) if player_bet.on?

      when CrapsBet::RETURN
        return_was_off(player_bet)

      when CrapsBet::MORPH
        morph_bet(player_bet)

      when CrapsBet::NONE
        # do nothing
      end
    end

    remove_marked_bets
  end

  private 

  def mark_bet_deleted(player_bet)
    player_bet.remove = true
  end

  def morph_bet(player_bet)
    dest_bet_box = table.find_bet_box(player_bet.craps_bet.morph_bet_name, table.last_roll)
    dest_bet_box.new_player_bet(player_bet.player, player_bet.amount)
    mark_bet_deleted(player_bet)
  end

  def remove_marked_bets
    #
    # because we can't delete bets from the bet arrays while iterating over them,
    # we delete bets marked as remove here
    #
    player_bets.delete_if {|b| b.remove}
  end

  def return_was_off(player_bet)
    player_bet.return_bet
    yield player_bet, CrapsBet::RETURN, player_bet.amount 
    mark_bet_deleted(player_bet)
  end

  def pay_winning(player_bet)
    #
    # table credits player rail with winning amount
    #
    winnings = player_bet.pay_winning_bet(craps_bet.pay_this, craps_bet.for_every) 
    yield player_bet, CrapsBet::WON, winnings 
    mark_bet_deleted(player_bet) unless craps_bet.bet_remains_after_win?
  end

  def take_losing(player_bet)
    #
    # table takes bet amount from player's wagers to house
    # player removes bet
    #
    amount = player_bet.amount
    player_bet.losing_bet
    yield player_bet, CrapsBet::LOSE, amount
    mark_bet_deleted(player_bet)
  end

end
