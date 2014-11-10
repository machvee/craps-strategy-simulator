class ComeOutBetMaker < OddsBetMaker
  def initialize(player)
    super(player, ComeOutBet.short_name, nil)
  end

  private

  def already_made_the_required_number_of_bets
    #
    # count the number of ComeBets and compare against @number_of_bets
    #
    return false if @number_of_bets.nil?

    bets_made = player.bets.count{|b| b.craps_bet.short_name == ComeBet.short_name}
    bets_made <= @number_of_bets
  end
end
