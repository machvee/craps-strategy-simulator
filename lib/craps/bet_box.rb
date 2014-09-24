class BetBox
  attr_reader :table
  attr_reader :craps_bet
  attr_reader :dice_bet_stat   # keeps table stats on outcome of dice

  attr_reader :player_bets
  attr_reader :tracking_bet

  delegate :name, :number, to: :craps_bet

  def initialize(table, craps_bet)
    @table = table
    @craps_bet = craps_bet
    @dice_bet_stat = craps_bet.add_bet_stats_to_collection(@table.dice_bet_stats)
    craps_bet.add_bet_stats_to_collection(@table.player_bet_stats)

    @player_bets = []
  end

  def short_name
    craps_bet.class.short_name
  end

  def new_player_bet(player, amount)
    PlayerBet.new(player, self, amount).tap do |pb|
      player_bets << pb
    end
  end

  def settle_player_bets(&block)
    outcome = craps_bet.outcome

    update_dice_bet_stats(outcome) if craps_bet.on?

    player_bets.each do |player_bet|
      case outcome
      when CrapsBet::Outcome::WIN
        if player_bet.on?
          winnings = pay_winning(player_bet)
          yield player_bet, CrapsBet::Outcome::WIN, winnings 
        end

      when CrapsBet::Outcome::LOSE
        if player_bet.on?
          take_losing(player_bet)
          yield player_bet, CrapsBet::Outcome::LOSE, player_bet.amount
        end

      when CrapsBet::Outcome::RETURN
        return_was_off(player_bet)
        yield player_bet, CrapsBet::Outcome::RETURN, player_bet.amount 

      when CrapsBet::Outcome::MORPH
        morph_bet(player_bet)

      when CrapsBet::Outcome::NONE
        # do nothing
      end
    end

    remove_marked_bets
  end

  def remove_bet(player_bet)
    mark_bet_deleted(player_bet)
    remove_marked_bets
  end

  private 

  def update_dice_bet_stats(outcome)
    case outcome
    when CrapsBet::Outcome::WIN
      dice_bet_stat.won
    when CrapsBet::Outcome::LOSE
      dice_bet_stat.lost
    end
  end

  def mark_bet_deleted(player_bet)
    player_bet.remove = true
  end

  def morph_bet(player_bet)
    dest_bet_box = table.find_bet_box(player_bet.craps_bet.morph_bet_name, table.last_roll)
    new_player_bet = dest_bet_box.new_player_bet(player_bet.player, player_bet.amount)
    player_bet.player.bets << new_player_bet
    mark_bet_deleted(player_bet)
  end

  def remove_marked_bets
    player_bets.select {|p| p.remove}.each {|p| p.player.remove_from_player_bets(p)}
    player_bets.delete_if {|p| p.remove}
  end

  def return_was_off(player_bet)
    player_bet.return_bet
    mark_bet_deleted(player_bet)
  end

  def pay_winning(player_bet)
    #
    # table credits player rail with winning amount
    #
    winnings = player_bet.pay_winning_bet(craps_bet.pay_this, craps_bet.for_every) 
    mark_bet_deleted(player_bet)
    winnings
  end

  def take_losing(player_bet)
    #
    # table takes bet amount from player's wagers to house
    # player removes bet
    #
    amount = player_bet.amount
    player_bet.losing_bet
    mark_bet_deleted(player_bet)
  end

end
