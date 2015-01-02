require 'rails_helper'

  class Counter
    include Watchable
    attr_reader :val
  
    def initialize(start=0)
      @val = start
    end
 
    def inc(incr=1)
      @val += incr
      check_watchers # call this when state changes
    end

    def reset(start=0)
      @val = start
      clear_watchers
    end
 end

 class Life
   attr_reader :current_age
   attr_reader :name
   attr_reader :status

   SCHOOL_AGE=5..18
   TEENAGER=13..19
   ADULTHOOD=21
   OLD_FART=64
   CENTURY=100

   def initialize(name)
     @name = name
     @current_age = Counter.new

     current_age.watch("school_age", Proc.new {|age| SCHOOL_AGE.include?(age.val)}) do
       milestone "Catch the Bus!"
     end

     current_age.watch("teenager", Proc.new {|age| TEENAGER.include?(age.val)}) do
       milestone "You're a teen.  Be rebellious!"
     end

     current_age.watch("adulthood", Proc.new {|age| age.val == ADULTHOOD}) do
       milestone "Grown-up"
     end

     current_age.watch("old", Proc.new {|age| age.val > OLD_FART}) do
       milestone "Dude you're officially old"
     end

     current_age.watch("centurion", Proc.new {|age| age.val == CENTURY}) do
       milestone "YOU MADE IT TO 100!!"
     end
   end

   def birthday
      current_age.inc
   end

   def drop_out
     current_age.stop_watching("school_age")
   end

   def milestone(str)
     @status = str
   end

   def reborn
     current_age.reset
   end
 end

describe Watchable do
  before(:each) do
     @life = Life.new("dave")
  end

  it "should be not school age before age 5" do
    expect(@life).not_to receive(:milestone)
    4.times {@life.birthday}
  end

  it "should be school age after age 5 up to 18 and keep calling milestone" do
    cnt = 11
    expect(@life).to receive(:milestone).with(/Bus/).exactly((cnt-5)+1).times
    cnt.times {@life.birthday}
  end

  it "should be school age and teen age from 13 to 16" do
    cnt = 16
    expect(@life).to receive(:milestone).with(/Bus/).at_least :once
    expect(@life).to receive(:milestone).with(/rebellious/).exactly((cnt-13)+1).times
    cnt.times {@life.birthday}
  end

  it "should possibly be a drop-out and no longer have to catch a bus but still be rebellious" do
    cnt = 13
    expect(@life).to receive(:milestone).with(/Bus/).at_least :once
    expect(@life).to receive(:milestone).with(/rebellious/).once
    cnt.times {@life.birthday}

    @life.drop_out

    new_cnt = 5
    expect(@life).not_to receive(:milestone).with(/Bus/)
    expect(@life).to receive(:milestone).with(/rebellious/).exactly(5).times
    new_cnt.times {@life.birthday}
  end

  it "should grow-up get old" do
    cnt = 67
    expect(@life).to receive(:milestone).with(/Bus/).at_least :once
    expect(@life).to receive(:milestone).with(/rebellious/).at_least :once
    expect(@life).to receive(:milestone).with(/Grown-up/).once
    expect(@life).to receive(:milestone).with(/officially old/).exactly(cnt-64).times
    cnt.times {@life.birthday}
  end

  it "should get old and be reborn with no milestones" do
    cnt = 105
    expect(@life).to receive(:milestone).with(/Bus/).at_least :once
    expect(@life).to receive(:milestone).with(/rebellious/).at_least :once
    expect(@life).to receive(:milestone).with(/Grown-up/).once
    expect(@life).to receive(:milestone).with(/officially old/).at_least :once
    expect(@life).to receive(:milestone).with(/100/).once
    cnt.times {@life.birthday}
    @life.reborn
    expect(@life).not_to receive(:milestone)
    cnt.times {@life.birthday}
  end
end

