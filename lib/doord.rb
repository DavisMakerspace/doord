class DoorD
  def initialize(door, server, log)
    @door = door
    @server = server
    @log = log
    @clients = []
    @mutex = Mutex.new
  end
  def run
    @log.info "Starting DoorD"
    Thread.new{monitor}.abort_on_exception=true
    loop do
      client = @server.accept
      Thread.new{listen(client)}.abort_on_exception=true
    end
  end
  def monitor
    @log.info "Monitoring door"
    @door.monitor do |type, value|
      @mutex.synchronize { @clients.each { |c| c.puts "! #{type} #{value.inspect}" } }
    end
  end
  def listen client
    @log.info "Client #{client} connected"
    @mutex.synchronize { @clients << client }
    client.each do |cmd|
      case cmd.chomp
        when 'lock'
          @log.info "Client #{client} sending lock signal"
          Thread.new{ @mutex.synchronize{ @door.lock }}.abort_on_exception=true
        when 'unlock'
          @log.info "Client #{client} sending unlock signal"
          Thread.new{ @mutex.synchronize{ @door.unlock }}.abort_on_exception=true
        when 'opened'
          @log.info "Client #{client} queried opened"
          @mutex.synchronize{ client.puts ": opened #{@door.opened?.inspect}" }
        when 'locked'
          @log.info "Client #{client} queried locked"
          @mutex.synchronize{ client.puts ": locked #{@door.locked?.inspect}" }
        else
          @mutex.synchronize{ client.puts "? lock unlock opened locked" }
      end
    end
    @mutex.synchronize{ @clients.delete client }
    @log.info "Client #{client} disconnected"
  end
end
