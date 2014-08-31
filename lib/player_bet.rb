class PlayerBet
  attr_reader :name
  attr_reader :number
  attr_reader :amount
  attr_reader :player
  attr_reader :craps_bet
  attr_reader :bet_off

  delegate :table, to: :player

  def initialize(player, bet_class, amount, number=nil)
    @player = player
    @amount = amount
    @number = number
    @craps_bet = find_craps_bet(bet_class, number)
    craps_bet.validate(self, amount)
    craps_bet.add_bet(self)
    set_bet_on
  end

  def press(additional_amount)
    new_amount = amount + additional_amount
    craps_bet.validate(self, new_amount)
    @amount = new_amount
  end

  def stat_occurred(bet_stat_name)
    player.stats.occurred(bet_stat_name)
  end

  def stat_did_not_occur(bet_stat_name)
    player.stats.did_not_occur(bet_stat_name)
  end

  def stat_incr(bet_stat_name)
    player.stats.incr(bet_stat_name)
  end

  def back_on
    set_bet_on
  end

  def off
    raise "You can't set your #{craps_bet} OFF" unless craps_bet.player_can_set_off?
    @bet_off = true
  end

  def on?
    #
    # could be set off by player or by the rules of the table
    # TODO: hardways follow the table.on, but can be set on/off at any time by the player
    #
    !bet_off && craps_bet.on?
  end

  def off?
    !on?
  end

  def determine_outcome
    craps_bet.determine_outcome(self)
  end

  def morph_bet(new_bet_class, number=nil)
    #
    # good for turning ComeOutBet into a ComeBet(number)
    # or moving a Place Bet 6 to a Place Bet 8 after a Point of 6 is
    # established
    #
    craps.bet.remove_bet(self)
    @craps_bet = find_craps_bet(new_bet_class, number)
    craps_bet.add_bet(self)
  end

  def remove_from_table
    craps_bet.remove_bet(self)
  end

  def to_s
    "$#{amount} #{craps_bet}"
  end

  def inspect
    to_s
  end

  private

  def set_bet_on
    @bet_off = false
  end

  def find_craps_bet(bet_class, number)
    table.find_craps_bet(bet_class, number) || raise("that's not a valid bet")
  end
end
