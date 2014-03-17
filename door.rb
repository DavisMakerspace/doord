class Door
  SIGNAL_DURATION = 0.5
  def initialize(lock, unlock, locked, unlocked, opened)
    @lock = lock
    @unlock = unlock
    @locked = locked
    @unlocked = unlocked
    @opened = opened
    [@lock,@unlock].each{|g|g.set_output_low}
    [@locked,@unlocked,@opened].each{|g|g.set_input.set_edge_both}
  end
  def lock
    begin
      @lock.set_high
      sleep SIGNAL_DURATION
    ensure
      @lock.set_low
    end
  end
  def unlock
    begin
      @unlock.set_high
      sleep SIGNAL_DURATION
    ensure
      @unlock.set_low
    end
  end
  def locked?
    if @locked.high? && @unlocked.low?
      return true
    elsif @locked.low? && @unlocked.high?
      return false
    else
      return nil
    end
  end
  def opened?
    return @opened.high?
  end
  def monitor
    last_msg = nil
    loop do
      @lock.class.select([@opened, @locked, @unlocked]).each do |gpio|
        msg = case gpio
          when @opened then [:opened, opened?]
          when @locked, @unlocked then [:locked, locked?]
        end
        yield msg if msg != last_msg
        last_msg = msg
      end
    end
  end
end
