class BetMaker
  #
  # specify the bet and initial amount
  # specify when the bet is initially made
  # specify when to press it after win and by how much
  #
  attr_reader   :player
  attr_reader   :table
  attr_reader   :bet
  attr_reader   :odds_bet_multiple
  attr_reader   :amount
  attr_reader   :rules
  attr_reader   :bet_presser

  FULL_ODDS = -1 # this indicates full odds when odds bet is made

  delegate :table, to: :player
  delegate :table_state, to: :table

  def initialize(player)
    @player = player
    @bet = nil
    @amount = nil
    @rules = nil
    @bet_presser = BetPresser.new
    @odds_bet_multiple = nil
  end
end
