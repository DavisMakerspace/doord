require '/usr/lib/doord/gpio'

class Door
  def initialize(lock: nil, unlock: nil, locked: nil, unlocked: nil, opened: nil)
    @SIGNAL_DURATION = 0.5
    @LOCKING_TIMEOUT = 2
    @lock = GPIO.new(lock, :low)
    @unlock = GPIO.new(unlock, :low)
    @locked = GPIO.new(locked, :in, :both)
    @unlocked = GPIO.new(unlocked, :in, :both)
    @opened = GPIO.new(opened, :in, :both)
    @poller = GPIOPoller.new([@opened, @locked, @unlocked])
    @mutex = Mutex.new
    @was_locked = nil
    @lock.clear
    @unlock.clear
  end
  def lock()
    @mutex.synchronize do
      begin
        @lock.set
        sleep @SIGNAL_DURATION
      ensure
        @lock.clear
      end
    end
  end
  def unlock()
    @mutex.synchronize do
      begin
        @unlock.set
        sleep @SIGNAL_DURATION
      ensure
        @unlock.clear
      end
    end
  end
  def locked?()
    if @locked.value && !@unlocked.value
      return true
    elsif !@locked.value && @unlocked.value
      return false
    else
      return nil
    end
  end
  def opened?()
    return @opened.value
  end
  def monitor()
    @poller.run() do |gpio, value|
      case gpio
      when @opened
        yield :opened, value
      when @locked, @unlocked
        is_locked = self.locked?
        if is_locked == nil
          @poller.timeout = @LOCKING_TIMEOUT
        else
          changed = (is_locked != @was_locked)
          @was_locked = is_locked
          @poller.timeout = nil
          yield :locked, is_locked if changed
        end
      when nil
        @poller.timeout = nil
        @was_locked = nil
        yield :locked, nil
      end
    end
  end
end
