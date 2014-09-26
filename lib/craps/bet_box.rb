class BetBox
  attr_reader :table
  attr_reader :craps_bet

  attr_reader :player_bets

  delegate :name, :number, to: :craps_bet

  def initialize(table, craps_bet)
    @table = table
    @craps_bet = craps_bet
    craps_bet.add_bet_stats_to_collection(@table.tracking_bet_stats)
    craps_bet.add_bet_stats_to_collection(@table.player_bet_stats)

    @player_bets = []
  end

  def short_name
    craps_bet.class.short_name
  end

  def new_player_bet(player, amount)
    player.new_bet(self, amount).tap do |pb|
      player_bets << pb
    end
  end

  def settle_player_bets(&block)
    outcome = craps_bet.outcome

    player_bets.each do |player_bet|
      case outcome
        when CrapsBet::Outcome::WIN
          if player_bet.on?
            player_bet.winning_bet(craps_bet.pay_this, craps_bet.for_every) 
            mark_bet_deleted(player_bet)
          end

        when CrapsBet::Outcome::LOSE
          if player_bet.on?
            player_bet.losing_bet
            mark_bet_deleted(player_bet)
          end

        when CrapsBet::Outcome::RETURN
          player_bet.return_bet
          mark_bet_deleted(player_bet)

        when CrapsBet::Outcome::MORPH
          #
          # delay the morphing so we don't settle the new
          # morphed bet on this iteration thru bet_boxes
          #
          table.morph_bets << player_bet
          mark_bet_deleted(player_bet)

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

  def mark_bet_deleted(player_bet)
    player_bet.remove = true
  end

  def remove_marked_bets
    player_bets.select {|p| p.remove}.each {|p| p.player.remove_from_player_bets(p)}
    player_bets.delete_if {|p| p.remove}
  end

end
